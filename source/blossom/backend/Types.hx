package blossom.backend;

typedef Int8 = #if cpp cpp.Int8 #elseif hl hl.UI8 #else Int #end;
typedef UInt8 = #if cpp cpp.UInt8 #else Int #end;
typedef UInt = #if cpp cpp.UInt32 #else Int #end;