class Journal < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  default_scope { order('held_at DESC', :id).joins(:kid) }

  belongs_to :kid
  belongs_to :mentor
  has_many :comments, -> { order('created_at ASC') }, dependent: :destroy

  validates_presence_of :kid, :mentor, :held_at
  validates_presence_of :start_at, :end_at, unless: :cancelled

  before_validation :clean_times, if: :cancelled
  before_save :calculate_duration
  before_save :calculate_week
  before_save :calculate_year
  before_save :calculate_month

  def display_name
    return 'Neuer Lernjournal Eintrag' if new_record?
    # altough held_at is mandatory for saved records, it may
    # temporarily be nil (edit with invalid data), this has to
    # be guarded
    return "Journal vom #{I18n.l(held_at.to_date)}" if held_at
    'Journal'
  end

  def human_goal
    text_format(goal)
  end

  def human_subject
    text_format(subject)
  end

  def human_method
    text_format(method)
  end

  def human_outcome
    text_format(outcome)
  end

  def human_note
    text_format(note)
  end

  def human_start_at
    return nil unless start_at
    I18n.l(start_at, format: :time)
  end

  def human_end_at
    return nil unless end_at
    I18n.l(end_at, format: :time)
  end

  # there is a default entry per month which represents the administrative
  # costs.
  #
  # This is display only yet.
  def self.coaching_entry(mentor, month, year)
    held_at = Date.new(year.to_i, month.to_i).end_of_month
    Journal.new(mentor: mentor, held_at: held_at, duration: 60)
  end

  protected

  def clean_times
    self.end_at = nil
    self.start_at = nil
  end

  def calculate_duration
    self.duration = (cancelled? ? 0 : (end_at - start_at) / 60)
  end

  def calculate_week
    self.week = held_at.strftime('%U').to_i
  end

  def calculate_year
    self.year = held_at.year
  end

  def calculate_month
    self.month = held_at.month
  end
end
