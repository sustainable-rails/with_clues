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

  class MyCustomClueThatNeedsThePage
    def dump(notifier, context:, page:)
      notifier.notify "YUP"
    end
  end

  WithClues::Method.use_custom_clue(MyCustomClue)
  WithClues::Method.use_custom_clue(MyCustomClueThatNeedsThePage)

  let(:fake_stdout) { StringIO.new }
  before do
    @stdout = $stdout
    $stdout = fake_stdout
  end

  after do
    $stdout = @stdout
  end

  context "clues that won't work" do
    context "no dump method" do
      it "raises an error" do
        clazz = Class.new
        expect {
          WithClues::Method.use_custom_clue(clazz)
        }.to raise_error(NameError,/undefined method.*dump/)
      end
    end
    context "has a dump method" do
      context "takes one arg" do
        it "raises an error" do
          clazz = Class.new
          clazz.define_method(:dump) do |x|
          end
          expect {
            WithClues::Method.use_custom_clue(clazz)
          }.to raise_error(NameError,/dump must take one required param, one keyword param named context: and an optional keyword param named page:/)
        end
      end
      context "takes 2 args" do
        context "second arg is context:" do
          it "works" do
            clazz = Class.new
            clazz.define_method(:dump) do |x, context: |
            end
            expect {
              WithClues::Method.use_custom_clue(clazz)
            }.not_to raise_error
          end
        end
        context "second arg is not context:" do
          it "raises an error" do
            clazz = Class.new
            clazz.define_method(:dump) do |x, not_context: |
            end
            expect {
              WithClues::Method.use_custom_clue(clazz)
            }.to raise_error(NameError,/not_context:/)
          end
        end
      end
      context "takes 3 args" do
        context "third arg is page:" do
          it "works" do
            clazz = Class.new
            clazz.define_method(:dump) do |x, context: , page:|
            end
            expect {
              WithClues::Method.use_custom_clue(clazz)
            }.not_to raise_error
          end
        end
        context "second arg is page:, third is context:" do
          it "works" do
            clazz = Class.new
            clazz.define_method(:dump) do |x, page:, context: |
            end
            expect {
              WithClues::Method.use_custom_clue(clazz)
            }.not_to raise_error
          end
        end
        context "third arg is not page:" do
          it "raises an error" do
            clazz = Class.new
            clazz.define_method(:dump) do |x, page:, foo: |
            end
            expect {
              WithClues::Method.use_custom_clue(clazz)
            }.to raise_error(NameError,/foo:/)
          end
        end
      end
      context "takes 4 args" do
        it "raises an error" do
          clazz = Class.new
          clazz.define_method(:dump) do |x, page:, foo:, bar: |
          end
          expect {
            WithClues::Method.use_custom_clue(clazz)
          }.to raise_error(NameError,/dump must take one required param, one keyword param named context: and an optional keyword param named page:/)
        end
      end
    end
  end

  context "not in a browser context" do
    it "includes only the non-browser custom clue on a test failure" do
      expect {
        with_clues do
          expect(true).to eq(false)
        end
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      expect(fake_stdout.string).to     match(/\[ with_clues \] OH YEAH/)
      expect(fake_stdout.string).not_to match(/\[ with_clues \] YUP/)
    end
  end
  context "in a browser context" do
    before do
      Object.define_method(:page) do
        Object.new
      end
    end

    after do
      Object.remove_method(:page)
    end

    it "includes the browser custom clue as well on a test failure" do
      expect {
        with_clues do
          expect(true).to eq(false)
        end
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      expect(fake_stdout.string).to match(/\[ with_clues \] OH YEAH/)
      expect(fake_stdout.string).to match(/\[ with_clues \] YUP/)
    end
  end
end
