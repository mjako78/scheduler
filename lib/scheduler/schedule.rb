module Scheduler
  class Schedule
    attr_accessor :teams, :legs, :shuffle, :start_date, :end_date, :start_week, :end_week, :span
    attr_reader   :gamedays

    def initialize(teams, params = {})
      raise "You have specified a repeating team"  unless teams.uniq == teams
      raise "You need to specify at least 2 teams" unless teams.size >= 2
      begin
        @start_date = params[:start_date].nil? ? nil : Date.parse(params[:start_date])
        @end_date   = params[:end_date].nil? ?   nil : Date.parse(params[:end_date])
      rescue ArgumentError
        raise "You have specified invalid dates"
      end
      @start_week = params[:start_week].nil? ? nil : params[:start_week]
      @end_week   = params[:end_week].nil? ?   nil : params[:end_week]
      raise "You have specified invalid dates" unless valid_dates?

      @teams      = teams
      @legs       = params[:legs] || 2
      @shuffle    = params[:shuffle].nil? ? true : params[:shuffle]
      if !with_dates? && !with_weeks?
        @start_date = Date.new(Date.today.year, 3, 15)
        @end_date   = Date.new(Date.today.year, 9, 30)
      end
      @teams << nil if teams.size.odd?
      @gamedays = []
      @span     = false
    end

    def generate
      @teams.shuffle! if @shuffle
      current_leg = 0
      current_round = 0

      # Loop to generate whole round-robin(s)
      begin
        t = @teams.clone
        games = []
        while !t.empty?
          team_a = t.shift
          team_b = t.reverse!.shift
          t.reverse!
          matchup = current_leg % 2 == 0 ? [team_a, team_b] : [team_b, team_a]
          games << { team_a: matchup[0], team_b: matchup[1] }
        end

        current_round += 1

        # Team rotation (the first team is fixed)
        @teams = @teams.insert(1, @teams.delete_at(@teams.size - 1))

        # Add round
        @gamedays << Scheduler::Gameday.new(
          round: current_round,
          leg:   current_leg + 1,
          round_with_leg: current_leg * (@teams.size - 1) + current_round,
          games: games.collect { |g| Scheduler::Game.new(team_a: g[:team_a], team_b: g[:team_b]) }
        )

        # Have we completed a full round-robin?
        if current_round == @teams.size - 1
          current_leg += 1
          current_round = 0 if current_leg < @legs
        end
      end until current_round == @teams.size - 1 && current_leg == @legs

      dispatch_weeks @start_week.upto(@end_week).to_a if with_weeks?
      dispatch_dates if with_dates?
    end

    # Returns true if start and / or end week are been spanned
    def spanned?
      @span
    end

    # Human readable schedule
    def to_s
      return "Schedule not yet generated" if @gamedays.empty?
      s = ""
      s << "#{@gamedays.size} gamedays\n"
      @gamedays.each do |gd|
        s << "=== Round #{gd.round_with_leg} [date: #{gd.date}] ===\n"
        gd.games.each do |g|
          s << "#{g.team_a} VS #{g.team_b}\n"
        end
      end
      s
    end

    private
      # Check if dates are valid
      def valid_dates?
        return true if @start_date.nil? &&
                       @end_date.nil? &&
                       @start_week.nil? &&
                       @end_week.nil?
        return false if with_dates? && with_weeks?
        return false if !with_dates? && !with_weeks?
        return @start_date < @end_date if with_dates?
        if with_weeks?
          return false unless @start_week.is_a?(Integer) && @end_week.is_a?(Integer)
          return false if @start_week <= 0 || @end_week <= 0
          return @start_week < @end_week
        end
        true
      end

      # Check if dates are specified
      def with_dates?
        return @start_week.nil? &&
               @end_week.nil? &&
               !@start_date.nil? &&
               !@end_date.nil?
      end

      # Check if weeks are specified
      def with_weeks?
        return @start_date.nil? &&
               @end_date.nil? &&
               !@start_week.nil? &&
               !@end_week.nil?
      end

      # Dispatch games into available weeks
      def dispatch_weeks weeks
        if @gamedays.size < weeks.size
          weeks = remove_weeks weeks, @gamedays.size
        elsif @gamedays.size > weeks.size
          weeks = add_weeks weeks, @gamedays.size
        end
        @gamedays.each.with_index { |gd, i| gd.date = weeks[i] }
      end

      # Dispatch games ingo available dates
      def dispatch_dates
        sundays = every_sunday(@start_date, @end_date)
        @start_date = sundays.first
        @end_date   = sundays.last
        if @gamedays.size < sundays.size
          dates = remove_dates sundays, @gamedays.size
        elsif @gamedays.size > sundays.size
          dates = add_dates sundays, @gamedays.size
        end
        @gamedays.each.with_index { |gd, i| gd.date = dates[i] }
      end

      # Returns all sundays dates between 2 dates
      def every_sunday d1, d2
        sundays = []
        sunday = d1 + ((7 - d1.wday) % 7)
        while sunday < d2
          sundays << sunday
          sunday += 7
        end
        sundays
      end

      # Remove some dates from the list
      def remove_dates dates, gamedays
        x = (0...gamedays).map {
          |i| (1 + i * (dates.size - 1) / (gamedays - 1.0)).round - 1
        }
        dates.to_a.values_at(*x)
      end

      # Add some dates to the list
      def add_dates dates, gamedays
        # byebug
        span_size = gamedays - dates.size
        span_before = span_size / 2
        span_after = span_size - span_before
        new_start_date = @start_date - (7 * span_before)
        if new_start_date.year < @start_date.year
          i = 0
          while new_start_date.year < @start_date.year
            new_start_date += 7
            i += 1
          end
          span_after += i
        end
        @start_date = new_start_date
        @end_date += (7 * span_after)
        @span = true
        (@start_date..@end_date).step(7).to_a
      end

      # Remove some weeks from the list
      def remove_weeks weeks, gamedays
        x = (0...gamedays).map {
          |i| (1 + i * (weeks.size - 1) / (gamedays - 1.0)).round - 1
        }
        weeks.to_a.values_at(*x)
      end

      # Add some weeks to the list
      def add_weeks weeks, gamedays
        span_size = gamedays - weeks.size
        span_before = span_size / 2
        span_after = span_size - span_before
        if @start_week - span_before < 1
          span_after += (span_before - @start_week + 1)
          @start_week = 1
        else
          @start_week -= span_before
        end
        @end_week += span_after
        @span = true
        @start_week.upto(@end_week).to_a
      end
  end
end
