module ardot::c3c::ast::internal @private;
import std::os::posix, std::os::process, std::io, std::collections::fixedlist, libc;

alias SegmentList = FixedList{Segment, 32};
struct InternalContext {
	SegmentList segments;
	bool loaded;
}

InternalContext context;

const ulong DUMP_SEGMENT_HEADER = 0xFD55C25FD5B9F4FE;
struct DumpSegment {
	ulong header;
	char[64] name_buf;
	void* start;
    sz length;
	bitstruct : ulong {
		bool next_segment_exists;
	}
    char[*] contents;
}

struct Segment (Printable) {
	char[64] name_buf;
	void* start;
	sz length;

	void* vmem;
	sz vmem_length;
}

fn ZString Segment.name(&self) => (ZString)&self.name_buf;

fn sz? Segment.to_format(&self, Formatter* formatter) @dynamic {
	return io::struct_to_format(*self, formatter, true);
}

fn void print_segments() {
	foreach(Segment segment : context.segments) {
		io::printn(segment);
	}
}

fn void? read_stdout(Process* self, void* ptr, sz size) {
	sz read = self.read_stdout(ptr, size)!;
	if(read < size) {
		return process::READ_FAILED~;
	}
}

fn void print_verbose(String format, args...)
{
	if(ast::context.settings.verbose) {
		io::eprintfn(format, ...args)!!;
	}
}

excuse {DUMP_FAILED, SEGMENT_NOT_FOUND}

fn void*? find_segment(String name) {
	foreach(Segment* &segment : context.segments) {
		if(segment.name().str_view() == name) {
			return segment.start;
		}
	}

	return SEGMENT_NOT_FOUND~;
}

fn void? read_dump(Process* process) {
	while(true) {
		DumpSegment segment;
		read_stdout(process, &segment, DumpSegment::size)!;
		if(segment.header != DUMP_SEGMENT_HEADER) {
			print_verbose("Invalid dump segment header detected.");
			return DUMP_FAILED~;
		}

		sz padding = 1024 * 16;
		void* mapping = posix::mmap(segment.start - padding, (usz)(segment.length + padding * 2), posix::PROT_READ | posix::PROT_WRITE, posix::MAP_ANONYMOUS | posix::MAP_PRIVATE, -1, 0);
		iptr offset = segment.start - mapping;
		if(offset < 0 || offset > padding * 2) {
			print_verbose("Failed to allocate vmem for segment %s", (ZString)&segment.name_buf);
			return DUMP_FAILED~;
		}

		context.segments.push({
			.name_buf = segment.name_buf,
			.start = segment.start,
			.length = segment.length,
			.vmem = mapping,
			.vmem_length = segment.length + padding * 2,
		});

		sz read = 0;
		while(read < segment.length) {
			read += process.read_stdout(segment.start + read, segment.length - read)!;
		}

		if(!segment.next_segment_exists) {
			break;
		}
	}

	ast::context = {
		... ast::context,
		.global = find_segment("global_context")!,
		.ast_arena = find_segment("ast_arena")!,
		.expr_arena = find_segment("expr_arena")!,
		.decl_arena = find_segment("decl_arena")!,
		.type_info_arena = find_segment("type_info_arena")!,
		.source_loc_arena = find_segment("sourceloc_arena")!,
	};
}

fn bool print_stderr(Process* process) {
	io::File stdout = process.stdout();
	// Need to empty out stdout here to prevent a deadlock. Ideally we would close the file,
	// but std::process would close it again later and cause a double free.
	while(!stdout.eof()) {
		char[1024 * 64] buf;
		stdout.read(&buf)!!;
	}

	bool error = false;
	io::File stderr = process.stderr();
	while(!stderr.eof()) {
		char[1024] buffer;
		sz read = stderr.read(&buffer)!!;
		if(read > 0) {
			error = true;
			if(ast::context.settings.print_stderr) {
				io::print((String)buffer[..read - 1]);
			}
		}
	}

	return error;
}

// fn int main(String[] args) @tag("test", true)
// {
// 	verbose = true;
	
// 	Process process = process::spawn({"c3cdev", "build", "--ast-dump"})!!;
// 	defer {
// 		process.join()!!;
// 		process.destroy();
// 	}

// 	bool failed = false;
// 	if(catch err = read_dump(&process)) {
// 		print_verbose("read_dump failed with error: %s", err);
// 		if(segments.size > 0) {
// 			print_verbose("Most recent segment was %s", segments[^1].name());
// 		}
// 		read_stderr(&process);
// 		return 1;
// 	}

// 	defer foreach(Segment segment : segments) {
// 		posix::munmap(segment.vmem, (usz)segment.vmem_length);
// 	}

// 	if(read_stderr(&process)) {
// 		return 1;
// 	}

// 	Module* this_module;
// 	@vec_foreach(context.global.module_list; Module* mod) {
// 		if(((ZString)mod.name.module_field).str_view() == "c3c_plugin") {
// 			this_module = mod;
// 		}
// 	};

// 	if(this_module != null) {
// 		@vec_foreach(this_module.units; CompilationUnit* unit) {
// 			@vec_foreach(unit.functions; Decl* decl) {
// 				assert(decl.decl_kind == DECL_FUNC);
// 				if(decl.attrs_resolved != null) {
// 					@vec_foreach(decl.attrs_resolved.tags; Attr* tag) {
// 						io::printn(c_string(tag.name));
// 					};
// 				}
				
// 				if(c_string(decl.type.name) == "main") {
// 					FuncDecl* func = &decl.func_decl;
// 					AstCompoundStmt* body = &ast_ptr(func.body).compound_stmt;
// 					Ast* current = ast_ptr(body.first_stmt);
// 					while(current != null) {
// 						io::printn(const_name(current.ast_kind));
// 						io::printn(source_loc_ptr(current.loc));
// 						current = ast_ptr(current.next);
// 					}
// 				}
// 			};
// 		};
// 	}

// 	return 0;
// }