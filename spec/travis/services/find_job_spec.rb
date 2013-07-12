require 'spec_helper'

describe Travis::Services::FindJob do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, repository: repo, state: :created, queue: 'builds.linux') }
  let(:params)  { { id: job.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds the job with the given id' do
      @params = { id: job.id }
      service.run.should == job
    end

    it 'does not raise if the job could not be found' do
      @params = { id: job.id + 1 }
      lambda { service.run }.should_not raise_error
    end

    it 'raises RecordNotFound if a SubclassNotFound error is raised during find' do
      find_by_id = stub
      find_by_id.stubs(:find_by_id).raises(ActiveRecord::SubclassNotFound)
      service.stubs(:scope).returns(find_by_id)
      lambda { service.run }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      service.updated_at.to_s.should == job.updated_at.to_s
    end
  end
end
