module Scheduler
  class Gameday
    attr_accessor :round, :leg, :round_with_leg, :games

    def initialize(params = {})
      @round = params[:round]
      @leg   = params[:leg]
      @round_with_leg = params[:round_with_leg]
      @games = params[:games] || []
    end
  end
end
