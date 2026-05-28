class Collab
  include FirestoreModel
  collection_name "collabs"
  # attributes:
  #   name, symbol, start_at (ISO8601), end_at (ISO8601),
  #   title_ids (Array<String>),
  #   currency_address (String, after deploy),
  #   deployed (bool), swept (bool)

  def quests;  Quest.where(collab_id: id);  end
  def rewards; Reward.where(collab_id: id); end

  def start_time
    Time.iso8601(attributes[:start_at].to_s)
  rescue ArgumentError
    nil
  end

  def end_time
    Time.iso8601(attributes[:end_at].to_s)
  rescue ArgumentError
    nil
  end
end

