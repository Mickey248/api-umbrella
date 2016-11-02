require_relative "../../test_helper"

class TestProxyApiKeyValidationBasicAuthParsing < Minitest::Test
  include ApiUmbrellaTests::Setup
  parallelize_me!

  def setup
    setup_server
  end

  def test_allows_case_insensitive_authorization_header
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "basIC #{Base64.strict_encode64("#{self.api_key}:")}",
      },
    }))
    assert_equal(200, response.code, response.body)
    assert_match("Hello World", response.body)
  end

  def test_allows_extra_spacing
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "  Basic      #{Base64.strict_encode64("#{self.api_key}:")}   ",
      },
    }))
    assert_equal(200, response.code, response.body)
    assert_match("Hello World", response.body)
  end

  def test_allows_ignored_password_value
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :userpwd => "#{self.api_key}:foobar",
    }))
    assert_equal(200, response.code, response.body)
    assert_match("Hello World", response.body)
  end

  def test_denies_empty_authorization
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_unknown_authorization
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "foo bar",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_requests_passing_key_in_password_not_username
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic #{Base64.strict_encode64(":#{self.api_key}")}",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_incorrect_authorization_scheme
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Digest #{Base64.strict_encode64("#{self.api_key}:")}",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_missing_password_separator
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Digest #{Base64.strict_encode64(self.api_key)}",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_basic_scheme_without_value_without_space
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_basic_scheme_without_value_with_space
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic ",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_invalid_base64_decodes_to_empty_string
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic z",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_invalid_base64_non_base64_chars
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic zF7&F@#@@",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end

  def test_denies_invalid_base64_decodes_to_binary
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", self.http_options.except(:headers).deep_merge({
      :headers => {
        "Authorization" => "Basic /9j/4AAQSkZJRgABAQAAAQABAAD//gA",
      },
    }))
    assert_equal(403, response.code, response.body)
    assert_match("API_KEY_MISSING", response.body)
  end
end
