# In-memory な Firestore 互換スタブ (テスト用)。
# 本物の Google::Cloud::Firestore::Client / CollectionReference / DocumentReference / Query
# のうち、本アプリの FirestoreModel が触る最低限の API だけを再現する。
module Fakes
  class FakeFirestore
    def initialize
      @collections = Hash.new { |h, k| h[k] = FakeCollection.new(k) }
    end

    def col(name);     @collections[name.to_s]; end
    def collection(n); col(n);                  end
    def reset!;        @collections.clear;      end
  end

  class FakeCollection
    attr_reader :name
    def initialize(name)
      @name = name
      @docs = {}  # id => Hash
    end

    def doc(id)
      FakeDoc.new(self, id.to_s)
    end

    def get
      @docs.map { |id, data| FakeSnapshot.new(id, data, true) }
    end

    def where(field, op, value)
      raise ArgumentError, "only == supported" unless op == "==" || op == :==
      FakeQuery.new(self, [[field.to_s, value]])
    end

    # 内部 API
    def _set(id, data); @docs[id] = deep_dup(data); end
    def _get(id);       @docs[id]; end
    def _delete(id);    @docs.delete(id); end
    def _scan;          @docs;            end

    private
    def deep_dup(o)
      case o
      when Hash  then o.each_with_object({}) { |(k, v), h| h[k] = deep_dup(v) }
      when Array then o.map { |x| deep_dup(x) }
      else o.dup rescue o
      end
    end
  end

  class FakeDoc
    def initialize(col, id); @col = col; @id = id; end
    def document_id; @id; end
    def set(data);   @col._set(@id, data); end
    def delete;      @col._delete(@id);    end
    def get
      data = @col._get(@id)
      FakeSnapshot.new(@id, data, !data.nil?)
    end
  end

  class FakeQuery
    def initialize(col, filters); @col = col; @filters = filters; end
    def get
      @col._scan.select { |_id, data|
        @filters.all? { |(f, v)| data && data[f.to_sym] == v || data && data[f] == v }
      }.map { |id, data| FakeSnapshot.new(id, data, true) }
    end
  end

  class FakeSnapshot
    attr_reader :document_id
    def initialize(id, data, exists); @document_id = id; @data = data || {}; @exists = exists; end
    def data;   @data;   end
    def exists?; @exists; end
  end
end

