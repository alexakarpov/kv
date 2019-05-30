defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "deletes a key from the bucket", %{bucket: bucket} do
    KV.Bucket.put(bucket, "milk", 3)

    assert KV.Bucket.delete(bucket, "milk") == 3
    assert KV.Bucket.get(bucket, "milk") == nil

  end

  test "deletes(2) a key from the bucket", %{bucket: bucket} do
    KV.Bucket.put(bucket, "milk", 3)

    assert KV.Bucket.delete2(bucket, "milk") == 3
    assert KV.Bucket.get(bucket, "milk") == nil

  end

end