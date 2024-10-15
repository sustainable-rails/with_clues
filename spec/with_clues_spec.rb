require "spec_helper"
require "ostruct"
require "stringio"

require "with_clues"

RSpec.describe WithClues::Method do
  include WithClues::Method
  let(:fake_stdout) { StringIO.new }
  before do
    @stdout = $stdout
    $stdout = fake_stdout
  end

  after do
    $stdout = @stdout
    undef page rescue nil
  end

  class LogsFromSomeBrowser
    def initialize(logs)
      @logs = logs.map { |log|
        OpenStruct.new(message: log)
      }
    end

    def get(sym)
      if sym != :browser
        raise "Don't know how to get(#{sym})"
      end
      @logs
    end
  end

  describe "#with_clues" do
    context "when code raises an exception" do
      context "and page is defined" do
        it "dumps the HTML, then raises" do
          def page
            OpenStruct.new(html: "some html", driver: OpenStruct.new())
          end
          expect {
            with_clues do
              expect(true).to eq(false)
            end
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
          aggregate_failures do
            expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
            expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
            expect(fake_stdout.string).to match(/some html/)
          end
        end
        it "includes context, if given" do
          def page
            OpenStruct.new(html: "some html", driver: OpenStruct.new())
          end
          expect {
            with_clues("some context") do
              expect(true).to eq(false)
            end
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
          aggregate_failures do
            expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
            expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
            expect(fake_stdout.string).to match(/some html/)
            expect(fake_stdout.string).to match(/some context/)
          end
        end
        context "and driver responds to browser" do
          context "and browser responds to manage" do
            context "and manage responds to logs" do
              it "dumps the logs" do
                def page
                  logs = LogsFromSomeBrowser.new([
                    "log line 1",
                    "log line 2",
                    "log line 3",
                  ])
                  OpenStruct.new(
                    html: "some html",
                    driver: OpenStruct.new(
                      browser: OpenStruct.new(
                        manage: OpenStruct.new(
                          logs: logs
                        )
                      )
                    )
                  )
                end
                expect {
                  with_clues do
                    expect(true).to eq(false)
                  end
                }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
                aggregate_failures do
                  expect(fake_stdout.string).to match(/\[ with_clues \] BROWSER LOGS \{/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] \} END BROWSER LOGS/)
                  expect(fake_stdout.string).to match(/log line 1/)
                  expect(fake_stdout.string).to match(/log line 2/)
                  expect(fake_stdout.string).to match(/log line 3/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
                  expect(fake_stdout.string).to match(/some html/)
                end
              end
            end
            context "but manage does not respond to logs" do
              it "raises and prints a warning" do
                def page
                  OpenStruct.new(
                    html: "some html",
                    driver: OpenStruct.new(
                      browser: OpenStruct.new(
                        manage: OpenStruct.new()
                      )
                    )
                  )
                end
                expect {
                  with_clues do
                    expect(true).to eq(false)
                  end
                }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
                aggregate_failures do
                  expect(fake_stdout.string).to match(/NO BROWSER LOGS/)
                  expect(fake_stdout.string).to match(/#{page.driver.browser.manage.class}/)
                  expect(fake_stdout.string).to match(/does not respond to #logs/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
                  expect(fake_stdout.string).to match(/some html/)
                end
              end
            end
          end
          context "but browser does not respond to manage" do
            it "raises and prints a warning" do
              def page
                OpenStruct.new(
                  html: "some html",
                  driver: OpenStruct.new(
                    browser: OpenStruct.new()
                  )
                )
              end
              expect {
                with_clues do
                  expect(true).to eq(false)
                end
              }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
              aggregate_failures do
                expect(fake_stdout.string).to match(/NO BROWSER LOGS/)
                expect(fake_stdout.string).to match(/#{page.driver.browser.class}/)
                expect(fake_stdout.string).to match(/does not respond to #manage/)
                expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
                expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
                expect(fake_stdout.string).to match(/some html/)
              end
            end
          end
        end
        context "but driver does not respond to browser" do
          it "raises and prints a warning" do
            def page
              OpenStruct.new(
                html: "some html",
                driver: OpenStruct.new()
              )
            end
            expect {
              with_clues do
                expect(true).to eq(false)
              end
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
            aggregate_failures do
              expect(fake_stdout.string).to match(/NO BROWSER LOGS/)
              expect(fake_stdout.string).to match(/#{page.driver.class}/)
              expect(fake_stdout.string).to match(/does not respond to #browser/)
              expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
              expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
              expect(fake_stdout.string).to match(/some html/)
            end
          end
        end
        context "but page does not respond to html" do
          context "but it does respond to #content as in Playwright" do
            it "prints the HTML" do
              def page
                OpenStruct.new(
                  content: "some html",
                )
              end
              expect {
                with_clues do
                  expect(true).to eq(false)
                end
              }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
              aggregate_failures do
                expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
                expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
                expect(fake_stdout.string).to match(/some html/)
              end
            end
            context "it also responds to on to record console logs" do
              it "includes those logs after the HTML" do
                def page
                  @page ||= begin
                              page = OpenStruct.new(
                                content: "some html"
                              )
                              def page.on(event,block)
                                if event == "console"
                                  @block = block
                                end
                              end
                              def page.trigger_logs
                                @block.(OpenStruct.new(text: "first console log"))
                                @block.(OpenStruct.new(text: "second console log"))
                              end
                              page
                            end
                end
                expect {
                  with_clues do
                    page.trigger_logs
                    expect(true).to eq(false)
                  end
                }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
                aggregate_failures do
                  expect(fake_stdout.string).to match(/\[ with_clues \] HTML \{/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] \} END HTML/)
                  expect(fake_stdout.string).to match(/some html/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] LOGS \{/)
                  expect(fake_stdout.string).to match(/\[ with_clues \] \} END LOGS/)
                  expect(fake_stdout.string).to match(/first console log/)
                  expect(fake_stdout.string).to match(/second console log/)
                end
              end
            end
          end
          context "nor does it respond to #content" do
            it "raises and prints a warning" do
              def page
                OpenStruct.new(
                  driver: OpenStruct.new()
                )
              end
              expect {
                with_clues do
                  expect(true).to eq(false)
                end
              }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
              aggregate_failures do
                expect(fake_stdout.string).to match(/Something may be wrong/)
                expect(fake_stdout.string).to match(/#{page.class}/)
                expect(fake_stdout.string).to match(/does not respond to #html/)
              end
            end
          end
        end
        context "but page does not respond to driver" do
          it "raises and prints a warning" do
            def page
              OpenStruct.new(
                html: "some html"
              )
            end
            expect {
              with_clues do
                expect(true).to eq(false)
              end
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
            aggregate_failures do
              expect(fake_stdout.string).to match(/Something may be wrong/)
              expect(fake_stdout.string).to match(/#{page.class}/)
              expect(fake_stdout.string).to match(/does not respond to #driver/)
            end
          end
        end
      end
      context "but page is not defined" do
        it "lets the error bubble up" do
          expect {
            with_clues do
              expect(true).to eq(false)
            end
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end
    end
    context "when code does not raise an exception" do
      it "logs that you should remove with_clues" do
        expect {
          with_clues do
            expect(true).to eq(true)
          end
        }.not_to raise_error
        expect(fake_stdout.string).to match(/passing.*remove/)
      end
    end
  end
end
