require "spec_helper"

RSpec.describe Scheduler do
  it "has a version number" do
    expect(Scheduler::VERSION).not_to be nil
  end

  context "initialization" do
    context "without parameters" do
      subject(:schedule) { Scheduler::Schedule.new }

      it 'should have default values' do
        expect(subject.teams.size).to eq 10
        expect(subject.cycles).to eq 2
        expect(subject.shuffle).to be true
      end
    end

    context "with parameters" do
      context "with even number of teams" do
        subject(:instance) { Scheduler::Schedule.new teams: %w[ Dragons Tigers Lions Hawks ] }

        it 'should have the setted values' do
          expect(subject.teams.size).to eq 4
        end
      end

      context "with odd number of teams" do
        subject(:instance) { Scheduler::Schedule.new teams: %w[ Dragons Tigers Lions Hawks Panthers ] }

        it 'should add a nil element to teams list' do
          expect(subject.teams).to include nil
          expect(subject.teams.size).to eq 6
        end
      end
    end
  end
end
