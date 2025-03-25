package bl.data;

typedef MeshData = {
	name:String,
	vertices:Array<Vertex>,
	indices:Array<UInt>,
	?material:Material,

	?minX:Float, ?maxX:Float,
	?minY:Float, ?maxY:Float,
	?minZ:Float, ?maxZ:Float
}

typedef Vertex = {
	x:Float,
	y:Float,
	z:Float,

	uvX:Float,
	uvY:Float,

	?normalX:Float,
	?normalY:Float,
	?normalZ:Float
}

typedef Material = {
	name:String,
	?diffuseTexture:String,
	?normalTexture:String,
	?specularTexture:String,
	?diffuseColor:Array<Float>,
	?ambientColor:Array<Float>,
	?specularColor:Array<Float>,
	?specularExponent:Float,
	?alpha:Float
}