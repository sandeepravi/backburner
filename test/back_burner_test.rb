require File.expand_path('../test_helper', __FILE__)

$backburner_sum = 0
$backburner_numbers = []

class TestBackburnerJob
  include Backburner::Queue
  queue "test.jobber"

  def self.perform(value, number)
    $backburner_sum += value
    $backburner_numbers << number
  end
end

describe "Backburner module" do
  before { Backburner.default_queues.clear }

  describe "for enqueue method" do
    before do
      Backburner.enqueue TestBackburnerJob, 5, 6
      Backburner.enqueue TestBackburnerJob, 15, 10
      silenced(2) do
        worker = Backburner::Worker.new('test.jobber')
        worker.prepare
        2.times { worker.work_one_job }
      end
    end

    it "can run jobs using #run method" do
      assert_equal 20, $backburner_sum
      assert_same_elements [6, 10], $backburner_numbers
    end
  end # enqueue

  describe "for work! method" do
    it "invokes worker start" do
      Backburner::Worker.expects(:start).with(["foo", "bar"])
      Backburner.work("foo", "bar")
    end
  end # work!

  describe "for configuration" do
    it "remembers the tube_namespace" do
      assert_equal "demo.test", Backburner.configuration.tube_namespace
    end
  end # configuration

  describe "for default_queues" do
    it "supports assignment" do
      Backburner.default_queues << "foo"
      Backburner.default_queues << "bar"
      assert_same_elements ["foo", "bar"], Backburner.default_queues
    end
  end
end # Backburner