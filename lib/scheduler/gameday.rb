module Scheduler
  class Gameday
    attr_accessor :round, :cycle, :round_with_cycle, :games

    def initialize(params = {})
      @round = params[:round]
      @cycle = params[:cycle]
      @round_with_cycle = params[:round_with_cycle]
      @games = params[:games] || []
    end
  end
end
