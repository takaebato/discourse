# frozen_string_literal: true

#
# Clean up a text
#

# We use ActiveSupport mb_chars from here to properly support non ascii downcase
require 'active_support/core_ext/string/multibyte'

class TextCleaner

  def self.title_options
    # cf. http://meta.discourse.org/t/should-we-have-auto-replace-rules-in-titles/5687
    {
      deduplicate_exclamation_marks: SiteSetting.title_prettify,
      deduplicate_question_marks: SiteSetting.title_prettify,
      replace_all_upper_case: SiteSetting.title_prettify && !SiteSetting.allow_uppercase_posts,
      capitalize_first_letter: SiteSetting.title_prettify,
      remove_all_periods_from_the_end: SiteSetting.title_prettify,
      remove_extraneous_space: SiteSetting.title_prettify && SiteSetting.title_remove_extraneous_space,
      fixes_interior_spaces: true,
      strip_whitespaces: true,
      strip_zero_width_spaces: true,
      case_option: SiteSetting.default_locale == "tr_TR" ? :turkic : nil
    }
  end

  def self.clean_title(title)
    TextCleaner.clean(title, TextCleaner.title_options)
  end

  def self.clean(text, opts = {})
    text = text.dup

    # Remove invalid byte sequences
    text.scrub!("")

    # Replace !!!!! with a single !
    text.gsub!(/!+/, '!') if opts[:deduplicate_exclamation_marks]

    # Replace ????? with a single ?
    text.gsub!(/\?+/, '?') if opts[:deduplicate_question_marks]

    # Replace all-caps text with regular case letters
    text = downcase(text.mb_chars, opts).to_s if opts[:replace_all_upper_case] && (text == upcase(text.mb_chars, opts))

    # Capitalize first letter, but only when entire first word is lowercase
    first, rest = text.split(' ', 2)
    if first && opts[:capitalize_first_letter] && first == downcase(first.mb_chars, opts)
      text = +"#{capitalize(first.mb_chars, opts)}#{rest ? ' ' + rest : ''}"
    end

    # Remove unnecessary periods at the end
    text.sub!(/([^.])\.+(\s*)\z/, '\1\2') if opts[:remove_all_periods_from_the_end]

    # Remove extraneous space before the end punctuation
    text.sub!(/\s+([!?]\s*)\z/, '\1') if opts[:remove_extraneous_space]

    # Fixes interior spaces
    text.gsub!(/ +/, ' ') if opts[:fixes_interior_spaces]

    # Normalize whitespaces
    text = normalize_whitespaces(text)

    # Strip whitespaces
    text.strip! if opts[:strip_whitespaces]

    # Strip zero width spaces
    text.gsub!(/\u200b/, '') if opts[:strip_zero_width_spaces]

    text
  end

  @@whitespaces_regexp = Regexp.new("(\u00A0|\u1680|\u180E|[\u2000-\u200A]|\u2028|\u2029|\u202F|\u205F|\u3000)", Regexp::IGNORECASE).freeze

  def self.normalize_whitespaces(text)
    text&.gsub(@@whitespaces_regexp, ' ')
  end

  def self.downcase(text, opts)
    opts[:case_option] ? text.downcase(opts[:case_option]) : text.downcase
  end

  def self.upcase(text, opts)
    opts[:case_option] ? text.upcase(opts[:case_option]) : text.upcase
  end

  def self.capitalize(text, opts)
    opts[:case_option] ? text.capitalize(opts[:case_option]) : text.capitalize
  end
end
