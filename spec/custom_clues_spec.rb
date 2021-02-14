require "spec_helper"
require "ostruct"
require "stringio"

require "with_clues"

RSpec.describe "custom clues" do
  include WithClues::Method

  class MyCustomClue
    def dump(notifier, context:)
      notifier.notify "OH YEAH"
    end
  end

  WithClues::Method.use_custom_clue(MyCustomClue)

  let(:fake_stdout) { StringIO.new }
  before do
    @stdout = $stdout
    $stdout = fake_stdout
  end

  after do
    $stdout = @stdout
    undef page rescue nil
  end

  it "includes my custom clue on a test failure" do
    expect {
      with_clues do
        expect(true).to eq(false)
      end
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    expect(fake_stdout.string).to match(/\[ with_clues \] OH YEAH/)
  end
end
