function _json_init()
  -- https://www.kyne.com.au/~mark/software/lua-cjson.php
  local json = {}
  cjson.decode_invalid_numbers(true) -- true
  cjson.decode_max_depth(256) -- 1000
  cjson.encode_invalid_numbers(false) -- false
  cjson.encode_keep_buffer(true) -- true
  cjson.encode_max_depth(256) -- 1000
  cjson.encode_number_precision(14) -- 14
  cjson.encode_sparse_array(true,1,1) -- false,2,10
  -- module modified so that decoding null -> nil
  json.encode = cjson.encode
  local _json_decode = cjson.decode
  json.decode = function (v) if not v or v == '' then return end return _json_decode(v) end
  cjson = nil
return json
end; json = _json_init(); _json_init = nil