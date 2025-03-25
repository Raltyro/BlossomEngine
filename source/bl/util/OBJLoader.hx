package bl.util;

import bl.data.MeshData;

using StringTools;

class OBJLoader {
	public static final SCALE_FACTOR:Float = 512.0;

	public static function loadAsset(path:String, ?flip = true):Array<MeshData> {
		final dir = Paths.dir(path);
		path = Paths.fixExt(path, 'obj');

		if (!AssetUtil.textExists(path)) {
			trace('Failed to load OBJ "$path"');
			return [];
		}

		final data = AssetUtil.getText(path);

		var mtlData:String = null;
		final mtlIdx = data.indexOf('mtllib');
		if (mtlIdx != -1 || data.startsWith('mtllib')) {
			final endIdx = data.indexOf('\n', mtlIdx + 7);
			final mtlPath = dir + '\\' + data.substring(mtlIdx + 7, endIdx == -1 ? data.length : endIdx);

			if (AssetUtil.textExists(mtlPath)) mtlData = AssetUtil.getText(mtlPath);
		}

		return loadString(data, mtlData, flip, dir);
	}

	public static function loadString(data:String, ?mtlData:String, ?flip:Bool = true, ?directory:String):Array<MeshData> {
		final meshs:Array<MeshData> = [], materials:Array<Material> = mtlData != null ? loadMTLFromString(mtlData, directory) : null;

		final _vertices:Array<Array<Float>> = [], _uvs:Array<Array<Float>> = [], _normals:Array<Array<Float>> = [];
		var curMesh:MeshData = null;

		final cache:Map<String, UInt> = [];
		for (line in data.split('\n')) {
			final splits = line.split(" ");
			switch (splits[0]) {
				case "v": _vertices.push([for (i in 1...4) Std.parseFloat(splits[i])]);
				case "vn": _normals.push([for (i in 1...4) Std.parseFloat(splits[i])]);
				case "vt": _uvs.push([for (i in 1...3) Std.parseFloat(splits[i])]);
				case "o": meshs.push(curMesh = {name: line.substr(2), vertices: [], indices: []});
				case "usemtl": if (curMesh == null) throw "OBJ data tries to implant material in a non-existing mesh!";
					final name = line.substr(7);
					if (materials != null) {
						for (material in materials) if (material.name == name) curMesh.material = material;
					}
				case "f": if (curMesh == null) throw "OBJ data tries to implant face in a non-existing mesh!";
					final indices:Array<UInt> = [];
					for (i in 1...splits.length) {
						if (cache.exists(splits[i])) {
							indices.push(cache.get(splits[i]));
							continue;
						}

						final faceIndices = splits[i].split("/");
						final vidx = Std.parseInt(faceIndices[0]) - 1, uidx = Std.parseInt(faceIndices[1]) - 1, nidx = Std.parseInt(faceIndices[2]) - 1;

						final idx = curMesh.vertices.length;
						final x = _vertices[vidx][0] * SCALE_FACTOR, y = _vertices[vidx][1] * SCALE_FACTOR, z = _vertices[vidx][2] * SCALE_FACTOR;

						if (x < curMesh.minX) curMesh.minX = x;
						else if (x > curMesh.maxX) curMesh.maxX = x;

						if (y < curMesh.minY) curMesh.minY = y;
						else if (y > curMesh.maxY) curMesh.maxY = y;

						if (z < curMesh.minZ) curMesh.minZ = z;
						else if (z > curMesh.maxZ) curMesh.maxZ = z;

						curMesh.vertices.push({x: x, y: flip ? -y : y, z: z, uvX: _uvs[uidx][0], uvY: flip ? -_uvs[uidx][1] + 1 : _uvs[uidx][1],
							normalX: _normals[nidx][0], normalY: _normals[nidx][1], normalZ: _normals[nidx][2]});

						cache.set(splits[i], idx);
						indices.push(idx);
					}

					switch (indices.length) {
						case 3: for (i in 0...3) curMesh.indices.push(indices[i]);
						case 4:
							curMesh.indices.push(indices[0]);
							curMesh.indices.push(indices[1]);
							curMesh.indices.push(indices[2]);

							curMesh.indices.push(indices[2]);
							curMesh.indices.push(indices[3]);
							curMesh.indices.push(indices[0]);
					}
			}
		}

		return meshs;
	}

	public static function loadMTLFromString(mtlData:String, ?directory:String):Array<Material> {
		final materials:Array<Material> = [];
		var curMaterial:Material = null;

		for (line in mtlData.split('\n')) {
			if (curMaterial != null) {
				if (line.startsWith('map_Kd')) curMaterial.diffuseTexture = line.substr(7);
				else if (line.startsWith('norm')) curMaterial.normalTexture = line.substr(5);
				else if (line.startsWith('map_Kn')) curMaterial.normalTexture = line.substr(7);
				else if (line.startsWith('Ns')) curMaterial.specularExponent = Std.parseFloat(line.substr(4));
				else if (line.startsWith('d ')) curMaterial.alpha = Std.parseFloat(line.substr(3));
				else if (line.charAt(0) == 'K') {
					final splits = line.split(" ");
					final color = [for (i in 1...4) Std.parseFloat(splits[i])];
					switch (line.substr(0, 2)) {
						case 'Ka': curMaterial.ambientColor = color;
						case 'Kd': curMaterial.diffuseColor = color;
						case 'Ks': curMaterial.specularColor = color;
					}
				}
			}
			else if (line.startsWith('newmtl')) {
				materials.push(curMaterial = {name: line.substring(7)});
			}
		}

		if (directory != null) {
			for (material in materials) {
				if (material.diffuseTexture != null) material.diffuseTexture = Paths.isAbsolute(material.diffuseTexture) ? material.diffuseTexture : '$directory\\${material.diffuseTexture}';
				if (material.normalTexture != null) material.normalTexture = Paths.isAbsolute(material.normalTexture) ? material.normalTexture : '$directory\\${material.normalTexture}';
				if (material.specularTexture != null) material.specularTexture = Paths.isAbsolute(material.specularTexture) ? material.specularTexture : '$directory\\${material.specularTexture}';
			}
		}

		return materials;
	}
}