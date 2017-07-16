module Scheduler
  class Game
    attr_accessor :team_a, :team_b
    
    def initialize(params = {})
      @team_a = params[:team_a]
      @team_b = params[:team_b]
    end
  end
end
