module Scheduler
  class Schedule
    attr_accessor :teams, :legs, :shuffle
    attr_reader   :gamedays

    def initialize(teams, params = {})
      raise "You have specified a repeating team"  unless teams.uniq == teams
      raise "You need to specify at least 2 teams" unless teams.size >= 2
      @teams   = teams
      @legs    = params[:legs] || 2
      @shuffle = params[:shuffle].nil? ? true : params[:shuffle]
      @teams << nil if teams.size.odd?
      @gamedays = []
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
    end

    # Human readable schedule
    def to_s
      return "Schedule not yet generated" if @gamedays.empty?
      s = ""
      s << "#{@gamedays.size} gamedays\n"
      @gamedays.each do |gd|
        s << "=== Round #{gd.round_with_leg} ===\n"
        gd.games.each do |g|
          s << "#{g.team_a} VS #{g.team_b}\n"
        end
      end
      s
    end
  end
end
