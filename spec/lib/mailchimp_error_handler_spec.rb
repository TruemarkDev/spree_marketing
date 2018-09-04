require 'spec_helper'

describe MailchimpErrorHandler, type: :module do
  include ActiveJob::TestHelper

  subject(:job) { TestJob.new }

  let(:retry_attempt) { 2 }

  SpreeMarketing::CONFIG = { Rails.env => { campaign_defaults: { from_email: 'a@test.com' } } }.freeze

  class TestJob < ActiveJob::Base
    include MailchimpErrorHandler

    def perform
      raise Gibbon::MailChimpError
    end
  end

  describe 'constants' do
    it 'RETRY_LIMIT equals to the limit for retrying failed job' do
      expect(MailchimpErrorHandler::RETRY_LIMIT).to eq 5
    end
  end

  describe '#retry_attempt' do
    it 'when unassigned returns default value' do
      expect(job.retry_attempt).to eq(1)
    end

    it 'when assigned returns assigned value' do
      job.instance_variable_set(:@retry_attempt, retry_attempt)
      expect(job.retry_attempt).to eq retry_attempt
    end
  end

  describe '#should_retry?' do
    it 'equals to true when should retry job' do
      expect(job.should_retry?(job.retry_attempt)).to eq(true)
    end
    it 'equals to false when should not retry job' do
      job.instance_variable_set(:@retry_attempt, MailchimpErrorHandler::RETRY_LIMIT + 1)
      expect(job.should_retry?(job.retry_attempt)).to eq(false)
    end
  end

  describe '#serialize' do
    it 'adds retry_attempt key to serialized arguments' do
      expect(job.serialize.keys).to include('retry_attempt')
    end
  end

  describe '#deserialize' do
    it 'defines retry_attempt attribute on job' do
      job.instance_variable_set(:@retry_attempt, retry_attempt)
      job.deserialize(job.serialize)
      expect(job.retry_attempt).to eq retry_attempt
    end
  end

  describe '#notify_admin' do
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before { allow(message_delivery).to receive(:deliver_later) }

    after { job.notify_admin(Gibbon::MailChimpError.new) }

    it 'Spree::Marketing::MailchimpErrorNotifier to receive notify_failure' do
      expect(Spree::Marketing::MailchimpErrorNotifier).to receive(:notify_failure).and_return(message_delivery)
    end
  end

  describe '#rescue_with_handler' do
    subject(:job) { TestJob.perform_later }

    before { perform_enqueued_jobs { job } }

    it 'notifies admin after more than RETRY_LIMIT failed attempts' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
