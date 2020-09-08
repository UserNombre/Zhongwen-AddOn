dictionary_in   = "cedict_ts.u8"
dictionary_out  = "cedict_ts.lua"
index_s_out     = "cedict_idx_s.lua"
index_t_out     = "cedict_idx_t.lua"

index_s = {}
index_t = {}

def add_offset(d, k, o):
    if k in d:
        d[k].append(o)
    else:
        d[k] = [o]

with open(dictionary_in, "r+b") as d:
    data = d.read()
    old_len = len(data)
    data = data.replace(b"\r", b"")
    if len(data) != old_len:
        d.seek(0)
        d.write(data)
        d.truncate()
        print("\\r removed! {} -> {}", old_len, len(data))

with open(dictionary_in, "rb")  as d_in, \
     open(dictionary_out, "wb") as d_out: 
    d_out.write(b"Zhongwen.Dictionary = \n[[")

    offset = 0
    for line in d_in:
        d_out.write(line)

        words = line.split(b" ")
        add_offset(index_s, words[0], offset)
        if words[0] != words[1]:
            add_offset(index_t, words[1], offset)

        offset = d_in.tell()

    d_out.write(b"]]")
    print("{} created".format(dictionary_out))

with open(index_s_out, "wb") as s:
    s.write(b"Zhongwen.IndexS = {\n")
    for k, v in index_s.items():
        offsets = ",".join(str(i) for i in v)
        s.write('["{}"] = "{}",\n'.format(k.decode(), offsets).encode())
    s.write(b"}")
    print("{} created".format(dictionary_out))

with open(index_t_out, "wb") as t:
    t.write(b"Zhongwen.IndexT = {\n")
    for k, v in index_t.items():
        offsets = ",".join(str(i) for i in v)
        t.write('["{}"] = "{}",\n'.format(k.decode(), offsets).encode())
    t.write(b"}")
    print("{} created".format(dictionary_out))