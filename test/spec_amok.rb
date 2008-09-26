require 'bacon'
require 'amok'

describe "Amok" do
  describe "without stubs" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)
    end

    should "not change behavior" do
      @obj.first.should.equal 1
      @obj.size.should.equal 3
      @obj.reverse.should.equal [3, 2, 1]
    end
  end

  describe "with stubs" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)
      @mock.on.size { Math::PI }
      @mock.on.reverse { self + super }
      @mock.on.pony { :oooh }
    end

    should "not modify unstubbed methods" do
      @obj.first.should.equal 1
    end

    should "override methods to be stubbed" do
      @obj.size.should.equal Math::PI
    end

    should "allow use of super to call the former definition" do
      @obj.reverse.should.equal [1, 2, 3, 3, 2, 1]
    end

    should "allow any parameters if none are declared" do
      should.not.raise(ArgumentError) { @obj.pony }
      should.not.raise(ArgumentError) { @obj.pony(:pink) }
    end
  end
  
  describe "with argumented stubs" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)

      @mock.on.fetch(0) { :one }
      @mock.on.fetch(1) { :two }
    end

    should "call the appropriate stub" do
      @obj.fetch(0).should.equal :one
      @obj.fetch(1).should.equal :two
      @obj.fetch(2).should.equal 3
    end
  end

  describe "with required calls" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)
      @mock.need.reverse
      @mock.on.first
    end

    should "check methods were called" do
      @obj.reverse
      @mock.should.be.successful
    end

    should "provide errors when methods were not called" do
      @obj.first
      @mock.should.not.successful
      @mock.errors.should.include("reverse was not called.")
    end
  end

  describe "with required, counted calls" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)
      @mock.need(3).reverse
    end

    should "check methods were called" do
      @obj.reverse
      @obj.reverse
      @obj.reverse
      @mock.should.be.successful
    end

    should "provide errors when methods were called not often enough" do
      @obj.reverse
      @mock.should.not.successful
      @mock.errors.should.include("reverse was called 2 times too few.")
    end

    should "provide errors when methods were called too often" do
      @obj.reverse
      @obj.reverse
      @obj.reverse
      @obj.reverse
      @mock.should.not.successful
      @mock.errors.should.include("reverse was called 1 times too often.")
    end

    should "provide exact messages in error messages" do
      @mock.need.fetch(42)
      @mock.should.not.successful
      @mock.errors.should.include("fetch(42) was not called.")
    end
  end
  
  describe "with forbidden calls" do
    before do
      @obj = [1, 2, 3]
      @mock = Amok.new(@obj)
      @mock.never.delete
    end
    
    should "provide errors when the method was called" do
      @obj.delete(1)
      @mock.should.not.be.successful
      @mock.errors.should.include("delete was called 1 times too often.")
    end
  end

  describe "mocks" do
    should "be easy to create from a hash" do
      @mock = Amok.make(:foo => 42, :bar => 69)
      @mock.foo.should.equal 42
      @mock.bar.should.equal 69
    end
  end
  
  should "provide a shortcut to check automatically" do
    should.not.raise {
      Amok.with([1, 2, 3]) { |obj, mock|
        mock.need.reverse
        obj.reverse
      }
    }

    should.raise(Amok::Failed) {
      Amok.with([1, 2, 3]) { |obj, mock|
        mock.need.reverse
      }
    }.errors.should.include("reverse was not called.")
  end
end
