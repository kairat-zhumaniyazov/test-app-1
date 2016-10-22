class YadAPI
  def self.get_campaigns(token)
    headers = {
      "Authorization": "Bearer #{token}",
      'Accept-Language': 'en'
    }

    query = {
      "method": "get",
      "params": {
        "SelectionCriteria": {},
        "FieldNames": [ "Id", "Name" ], #{"DailyBudget", "Funds", "Statistics", "Type" ],
        "TextCampaignFieldNames": ["RelevantKeywords" ],
      }
    }

    campaigns = HTTParty.post(
      "https://api-sandbox.direct.yandex.com/json/v5/campaigns",
      body: query.to_json,
      headers: headers
    ).parsed_response['result']['Campaigns']

    keywords = get_keywords(headers, campaigns.map{|c| c['Id']})

    # собираем в 1 хеш
    res = {}
    campaigns.each do |c|
      res.merge!(c['Id'] => c)
      res[c['Id']]['keywords'] = {}
    end
    keywords.each do |kw|
     res[kw['CampaignId']]['keywords'][kw['Id']] = kw
    end

    # подсчитываем суммы
    res.each do |c|
      c[1]['TotalBid'] = c[1]['keywords'].map{|h| h[1]['Bid']}.reduce(:+)
      c[1]['TotalClicks'] = c[1]['keywords'].map{|h| h[1]['StatisticsSearch']['Clicks']}.reduce(:+)
      c[1]['TotalImpressions'] = c[1]['keywords'].map{|h| h[1]['StatisticsSearch']['Impressions']}.reduce(:+)
    end
    res
  end

  def self.get_keywords(headers, campaigns_ids_arr)
    kw_query = {
      "method": "get",
      'params': {
        'SelectionCriteria': {
          "CampaignIds": campaigns_ids_arr
        },
        "FieldNames": ["Id", "CampaignId", "Keyword", "Bid", "ContextBid", "Productivity", 'StatisticsSearch']
      }
    }

    keywords = HTTParty.post(
      "https://api-sandbox.direct.yandex.com/json/v5/keywords",
      body: kw_query.to_json,
      headers: headers
    ).parsed_response['result']['Keywords']
  end
end