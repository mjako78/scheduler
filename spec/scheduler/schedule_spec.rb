require "spec_helper"

RSpec.describe Scheduler::Schedule do
  context '#initialize' do
    let(:teams)     { %w[ Dragons Tigers Lions Panthers ] }
    let(:curr_year) { Date.today.year }

    context "without parameters" do
      subject(:schedule) { Scheduler::Schedule.new teams }
      let(:default_start_date) { Date.new(curr_year, 3, 15) }
      let(:default_end_date)   { Date.new(curr_year, 9, 30) }

      it 'should have default values' do
        expect(subject.teams.size).to eq 4
        expect(subject.legs).to eq 2
        expect(subject.shuffle).to be true
        expect(subject.gamedays).to be_empty
        # Schedule can be based on weeks or dates, but not both
        # Default is dates
        expect(subject.start_date).to eq default_start_date
        expect(subject.end_date).to eq default_end_date
        expect(subject.start_week).to eq nil
        expect(subject.end_week).to eq nil
      end
    end

    context "with parameters" do
      context "with even number of teams" do
        subject(:instance) { Scheduler::Schedule.new teams, legs: 4, shuffle: false }

        it 'should have the setted values' do
          expect(subject.teams.size).to eq 4
          expect(subject.legs).to eq 4
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
      context 'with both dates and week or invalid ranges' do
        let(:start_date) { "15/3/2019" }
        let(:end_date)   { "30/9/2019" }
        let(:start_week) { 10 }
        let(:end_week)   { 40 }

        it 'should raise error if there is both date and week' do
          expect {
            Scheduler::Schedule.new teams, start_date: start_date, start_week: start_week
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if dates are invalid format' do
          expect {
            Scheduler::Schedule.new teams, start_date: start_date, end_date: "31/15/2019"
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if end_date is before start_date' do
          expect {
            Scheduler::Schedule.new teams, start_date: start_date, end_date: "5/2/2019"
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if not both start_date and end_date are specified' do
          expect {
            Scheduler::Schedule.new teams, start_date: start_date
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if not both start_week and end_week are specified' do
          expect {
            Scheduler::Schedule.new teams, start_week: start_week
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if end_week is before start_week' do
          expect {
            Scheduler::Schedule.new teams, start_week: start_week, end_week: 5
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if start_week or end_week are less or equal than zero' do
          expect {
            Scheduler::Schedule.new teams, start_week: -1, end_week: end_week
          }.to raise_error "You have specified invalid dates"
        end

        it 'should raise error if start_week or end_week are string' do
          expect {
            Scheduler::Schedule.new teams, start_week: "abc", end_week: end_week
          }.to raise_error "You have specified invalid dates"
        end
      end

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
    let(:schedule) { Scheduler::Schedule.new teams, start_week: 10, end_week: 40 }

    it 'should have a (teams / 2) games per gameday' do
      schedule.generate
      expect(schedule.gamedays).to_not be_empty
      schedule.gamedays.each { |gd| expect(gd.games.size).to eq(teams.size / 2) }
    end

    it 'should not have a team that play more than once per gameday' do
      schedule.generate
      expect(schedule.gamedays).to_not be_empty
      schedule.gamedays.each do |gd|
        gd_teams = gd.games.collect { |g| [g.team_a, g.team_b] }.flatten
        unique_gd_teams = gd_teams.uniq
        expect(gd_teams).to eq unique_gd_teams
      end
    end

    context "when gamedays are more than weeks" do
      let(:start_week) { 10 }
      let(:end_week)   { 20 }
      let(:schedule)   { Scheduler::Schedule.new teams,
        legs: 4,
        start_week: start_week,
        end_week: end_week
      }

      it 'should span start_week and end_week to accomodate all gamedays' do
        schedule.generate
        expect(schedule.spanned?).to be true
        expect(schedule.start_week.upto(schedule.end_week).size).to eq schedule.gamedays.size
      end
    end
  end
end
