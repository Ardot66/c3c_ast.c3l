module c3c_bindgen;
import std::io, std::os, bindgen;

fn int main(String[] args)
{
	io::File output = file::open("c3c.c3i", "w")!!;

	String c3c_path = "/home/ardot66/Projects/C3/c3c";
	if(args.len >= 2) {
		c3c_path = args[1];
	}

	if(!file::exists(c3c_path)) {
		io::eprintfn("Could not find c3c directory at path '%s'. You should pass the correct directory as the first arg to this script.", c3c_path);
		return 1;
	}

	String header_path = c3c_path.tconcat("/src/compiler/compiler_internal.h");

	BGTransFn ignore_fn = fn String(String name, Allocator alloc) => "";
	bg::translate_header(header_path, {
		.out_file = output,
		.module_name = "c3c",
		.include_file = fn bool(String name) {
			const String[] INCLUDE = {
				"enums.h",
				"target.h",
				"build.h",
				"utils/lib.h"
			};

			foreach(String header : INCLUDE) {
				if(name.ends_with(header)) {
					return true;
				}
			}
			return false;
		},
		.no_verbose,
	}, {
		.func = ignore_fn,
		.func_macro = ignore_fn,
		.global_variable = ignore_fn,
		.constant = ignore_fn,
		.variable = fn String(String name, Allocator alloc) {
			switch(name) {
				case "module":
				case "alias":
				case "defer":
				case "import":
				case "var":
				case "macro":
				case "typeid":
				case "fault":
				case "float128":
				case "float16":
				case "int128":
					return string::format(alloc, "%s_field", name);
				default:
					return name.copy(alloc);
			}
		},
		.type = fn String(String name, Allocator alloc) {
			if(name == "ABI") {
				return "Abi";
			} else if(name.ends_with("_")) {
				return name[..^2].copy(alloc);
			} else if(name.starts_with("Zip")) {
				return "";
			}

			return name.copy(alloc);
		},
		.type_alias = fn String(String name, Allocator alloc) {
			switch(name) {
				case "Signature":
				case "ConstInitializer":
				case "CompilationUnit":
				case "Ast":
				case "Decl":
				case "TypeInfo":
				case "Expr":
				case "Module":
				case "Type":
				case "SemaContext":
					return "";
				case "charId":
					return "CharId";
			}

			return name.copy(alloc);
		}
	})!!;

	int? result = process::run({"c3fmt", "-i", "src/c3c.c3i"}, );
	if(catch err = result) {
		io::eprintfn("Failed to run c3fmt pass with error: %s", err);
	} else if(result != 0) {
		io::eprintfn("c3fmt failed with exit code %s", result);
	}

	return 0;
}