module Scheduler
  class Schedule
    attr_accessor :teams, :legs, :shuffle, :start_week, :end_week, :span
    attr_reader   :gamedays

    def initialize(teams, params = {})
      raise "You have specified a repeating team"  unless teams.uniq == teams
      raise "You need to specify at least 2 teams" unless teams.size >= 2
      @teams      = teams
      @legs       = params[:legs] || 2
      @shuffle    = params[:shuffle].nil? ? true : params[:shuffle]
      @start_week = params[:start_week] || 10
      @end_week   = params[:end_week] || 40
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

      #dispatch_weeks(@gamedays, @start_week, @end_week)
      dispatch_weeks @start_week.upto(end_week).to_a
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
        s << "=== Round #{gd.round_with_leg} [week: #{gd.week}] ===\n"
        gd.games.each do |g|
          s << "#{g.team_a} VS #{g.team_b}\n"
        end
      end
      s
    end

    private
      # Dispatch games into available weeks
      def dispatch_weeks weeks
        if @gamedays.size < weeks.size
          weeks = remove_weeks weeks, @gamedays.size
        elsif @gamedays.size > weeks.size
          weeks = add_weeks weeks, @gamedays.size
        end
        @gamedays.each.with_index { |gd, i| gd.week = weeks[i] }
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
