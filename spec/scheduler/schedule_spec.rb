require "spec_helper"

RSpec.describe Scheduler::Schedule do
  context '#initialize' do
    let(:teams) { %w[ Dragons Tigers Lions Panthers ] }

    context "without parameters" do
      subject(:schedule) { Scheduler::Schedule.new teams }

      it 'should have default values' do
        expect(subject.teams.size).to eq 4
        expect(subject.cycles).to eq 2
        expect(subject.shuffle).to be true
        expect(subject.gamedays).to be_empty
      end
    end

    context "with parameters" do
      context "with even number of teams" do
        subject(:instance) { Scheduler::Schedule.new teams, cycles: 4, shuffle: false }

        it 'should have the setted values' do
          expect(subject.teams.size).to eq 4
          expect(subject.cycles).to eq 4
          expect(subject.shuffle).to be false
        end
      end

      context "with odd number of teams" do
        let(:teams) { %w[ Dragons Tigers Lions Hawks Panthers ] }
        subject(:instance) { Scheduler::Schedule.new teams }

        it 'should add a nil element to teams list' do
          expect(subject.teams).to include nil
          expect(subject.teams.size).to eq 6
        end
      end
    end

    context "with invalid parameters" do
      context "with repeating team" do
        let(:teams) { %w[ Dragons Tigers Lions Panthers Hawks Dragons ]}

        it 'should raise error if there is at least one repeating team' do
          expect { Scheduler::Schedule.new teams }.to raise_error "You have specified a repeating team"
        end
      end

      context "with less than 2 teams" do
        it 'should raise error if no teams are specified' do
          expect { Scheduler::Schedule.new [] }.to raise_error "You need to specify at least 2 teams"
        end

        it 'should raise error if there is only 1 team' do
          expect { Scheduler::Schedule.new ["Dragons"] }.to raise_error "You need to specify at least 2 teams"
        end
      end
    end
  end

  context '#generate' do
    let(:teams) { %w[ Dragons Tigers Lions Panthers ] }
    let(:schedule) { Scheduler::Schedule.new teams }

    before { schedule.generate }

    it 'should have a (teams / 2) games per gameday' do
      expect(schedule.gamedays).to_not be_empty
      schedule.gamedays.each { |gd| expect(gd.games.size).to eq(teams.size / 2) }
    end

    it 'should not have a team that play more than once per gameday' do
      expect(schedule.gamedays).to_not be_empty
      schedule.gamedays.each do |gd|
        gd_teams = gd.games.collect { |g| [g.team_a, g.team_b] }.flatten
        unique_gd_teams = gd_teams.uniq
        expect(gd_teams).to eq unique_gd_teams
      end
    end
  end
end
