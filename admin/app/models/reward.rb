class Reward
  include FirestoreModel
  collection_name "rewards"
  # attributes: collab_id, title_id, name, cost

  def self.where(collab_id:)
    col.where("collab_id", "==", collab_id).get.map { |s| new(s.data.merge(id: s.document_id)) }
  end
end

