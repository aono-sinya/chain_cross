# Firestore を使った簡易ドキュメントモデル基盤
module FirestoreModel
  extend ActiveSupport::Concern

  class_methods do
    def collection_name(name = nil)
      @collection_name = name if name
      @collection_name
    end

    def col
      FIRESTORE.col(collection_name)
    end

    def all
      col.get.map { |snap| new(snap.data.merge(id: snap.document_id)) }
    end

    def find(id)
      snap = col.doc(id).get
      return nil unless snap.exists?
      new(snap.data.merge(id: snap.document_id))
    end

    def create!(attrs)
      m = new(attrs)
      m.save!
      m
    end
  end

  attr_accessor :id, :attributes

  def initialize(attrs = {})
    attrs = attrs.transform_keys(&:to_sym)
    @id   = attrs.delete(:id) || SecureRandom.uuid
    @attributes = attrs
  end

  def [](k);            attributes[k.to_sym]; end
  def []=(k, v);        attributes[k.to_sym] = v; end
  def method_missing(name, *args)
    if name.to_s.end_with?("=")
      attributes[name.to_s.chomp("=").to_sym] = args.first
    elsif attributes.key?(name)
      attributes[name]
    else
      super
    end
  end
  def respond_to_missing?(name, include_private = false)
    attributes.key?(name.to_s.chomp("=").to_sym) || super
  end

  def to_param; id; end

  def save!
    self.class.col.doc(id).set(attributes)
    self
  end

  def update!(attrs)
    attrs.each { |k, v| attributes[k.to_sym] = v }
    save!
  end

  def destroy!
    self.class.col.doc(id).delete
  end

  def persisted?
    !id.nil?
  end
end

