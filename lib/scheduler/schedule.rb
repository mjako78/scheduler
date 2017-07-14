module Scheduler
  class Schedule
    attr_accessor :teams, :cycles, :shuffle

    def initialize(params = {})
      @teams  =  params[:teams]   || (1..10).to_a
      @cycles =  params[:cycles]  || 2
      @shuffle = params[:shuffle] || true
      @teams << nil if @teams.size.odd?
    end
  end
end
