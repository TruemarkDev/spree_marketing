require 'spec_helper'

RSpec.describe ListModificationJob, type: :job do
  include ActiveJob::TestHelper

  SpreeMarketing::CONFIG ||= { Rails.env => {} }.freeze

  class GibbonServiceTest; end

  subject(:job) { described_class.perform_later(list.id, users_data, [contact.uid]) }

  let(:gibbon_service) { GibbonServiceTest.new }
  let(:list) { create(:marketing_list) }
  let(:contact) { create(:marketing_contact) }
  let(:list_name) { 'test' }
  let(:emails) { ['test@example.com'] }
  let(:users_data) { { 'test@example.com' => 1 } }
  let(:list_class_name) { Spree::Marketing::List.subclasses.first.name }
  let(:contacts_data) { [{ id: '12345678', email_address: emails.first, unique_email_id: 'test' }.with_indifferent_access] }

  before do
    allow(GibbonService::ListService).to receive(:new).and_return(gibbon_service)
    allow(gibbon_service).to receive(:update_list).and_return(contacts_data)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'adds contacts to updated list' do
    perform_enqueued_jobs { job }
    expect(Spree::Marketing::List.first.contacts.first.email).to eq(emails.first)
  end

  it 'removes old contacts from updated list' do
    perform_enqueued_jobs { job }
    expect(Spree::Marketing::List.first.contacts).not_to include(contact)
  end

  it 'is in default queue' do
    expect(ListModificationJob.new.queue_name).to eq('default')
  end

  context 'executes perform' do
    after { perform_enqueued_jobs { job } }

    it 'expect GibbonService::ListService to be initialized' do
      expect(GibbonService::ListService).to receive(:new).with(list.uid).and_return(gibbon_service)
    end
    it 'expect initialized service to receive update_list' do
      expect(gibbon_service).to receive(:update_list).with(emails, [contact.uid]).and_return(contacts_data)
    end
  end
end
