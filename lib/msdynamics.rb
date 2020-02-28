require 'uri'
require 'net/http'
require 'hashie'
require 'json'

# Public: Various methods for accessing MS Dynamics.
class MSDynamics

  # Public: Initialize a MS Dynamics client instance.
  #
  # config - A configuration object.
  def initialize(config={
      hostname: nil, access_token: nil, tenant_id: nil,
      client_id: nil, client_secret: nil})
    # Validate the input.
    if config[:hostname].nil?  && config[:tenant_id].nil? && config[:client_secret].nil? && config[:client_id].nil?
      raise RuntimeError.new("hostname, client secret, client id and tenant_id are required")
    end
    # Set up the variables

    @tenant_id = config[:tenant_id]
    @hostname = config[:hostname]
    @client_id = config[:client_id]
    @client_secret = config[:client_secret]
    @access_token = MSDynamics.get_token("https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token",
      @client_id, @client_secret, @hostname)
    @endpoint = "#{@hostname}/api/data/v9.0/"
    # Get the authenticated user's information ('WhoAmI')
    # This also validates the access tokens and client secrets.
    # If validation fails, it will raise an exception back to the calling app.
    response = DynamicsHTTPClient.index("#{@endpoint}WhoAmI", @access_token)
    @user_id = JSON.parse(response.body)['UserId']
  end

  # Public: Gets all the records for a given MS Dynamics entity.
  #
  # entity_name  - 'accounts', 'leads', 'opportunities' or 'contacts'.
  #
  # Examples
  #
  #   get_entity_records('accounts')
  #   # => [
  #          {
  #            "@odata.etag": "W/\"640532\"",
  #            "name": "A. Datum",
  #            "emailaddress1": "vlauriant@adatum.com",
  #            "telephone1": "+86-23-4444-0100",
  #            "int_twitter": null,
  #            "int_facebook": null,
  #            "accountid": "475b158c-541c-e511-80d3-3863bb347ba8"
  #          }
  #        ]
  #
  # Returns an object with all records for the given entity.
  def get_entity_records(entity_name="", params="")
    # Add a filter so we only get records that belong to the authenticated user.
    request_url = "#{@endpoint}#{entity_name}?#{params}"
    # Return the array of records
    response = DynamicsHTTPClient.index(request_url, @access_token)
    Hashie::Mash.new(JSON.parse(response.body)).value
  end


  def update_entity_records(entity_name="", params="")
    # Add a filter so we only get records that belong to the authenticated user.
    request_url = "#{@endpoint}#{entity_name}"
    # Return the array of records
    response = DynamicsHTTPClient.update(request_url, @access_token, params)
    Hashie::Mash.new(JSON.parse(response.body)).value
  end

  def refresh_token()
    response = DynamicsHTTPClient.refresh_token(
      "https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token",
      @client_id, @client_secret, @hostname)
    token_object = Hashie::Mash.new(JSON.parse(response.body))
    @access_token = token_object.access_token
    @refresh_token = token_object.refresh_token
    token_object
  end


  def self.get_token(url="", client_id="", client_secret="", resource="")
    response = DynamicsHTTPClient.refresh_token(
      url,client_id, client_secret, resource)
    token_object = Hashie::Mash.new(JSON.parse(response.body))
    @access_token = token_object.access_token
    puts token_object
    @access_token
  end

end

# Private: Methods for making HTTP requests to the Dynamics Web API.
class DynamicsHTTPClient
  # Sends a HTTP request.(GET)
  def self.index(url="", access_token="")
      uri = URI(URI.encode(url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      response = http.request(request)
      if response.code != '200'
        if response.code == '401'
          # Ughhh! MS Dynamics puts the 401 error messages in the body!
          error_message = response.body
        else
          error_message = JSON.parse(response.body)['error']['message']
        end
        raise RuntimeError.new(error_message)
      end
      response
  end



  def self.update(url="", access_token="", data="")
      uri = URI(URI.encode(url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      request = Net::HTTP::Patch.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json; charset=utf-8"
      request["OData-MaxVersion"] = "4.0"
      request["OData-Version"] = "4.0"
      request["Prefer"] = "return=representation"
      request.body = data
      response = http.request(request)
      if response.code != '200'
        if response.code == '401'
          # Ughhh! MS Dynamics puts the 401 error messages in the body!
          error_message = response.body
        else
          error_message = JSON.parse(response.body)['error']['message']
        end
        raise RuntimeError.new(error_message)
      end
      response
  end

  # Allows refreshing an oAuth access token.
  def self.refresh_token(url="", client_id="", client_secret="", resource="")
    params = {
      'client_id'     => client_id,
      'client_secret' => client_secret,
      'grant_type'    => 'client_credentials',
      'scope'      => resource + "/.default"
    }
    uri = URI(url)
    Net::HTTP::post_form(uri, params)
  end
end
