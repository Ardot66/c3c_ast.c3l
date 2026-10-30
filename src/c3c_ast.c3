module ardot::c3c::ast;
import ardot::c3c::ast::internal @public;
import std::os::process, std::os::posix;

struct AstSettings {
	bitstruct : uint {
		bool verbose;
		bool print_stderr;
	}
}

struct AstContext {
	AstSettings settings;
    GlobalContext* global;
    Ast* ast_arena;
    Expr* expr_arena;
    Decl* decl_arena;
    TypeInfo* type_info_arena;
    SourceLoc* source_loc_arena;
}

AstContext context;

excuse {C3C_ERROR}

<*
 @require !internal::context.loaded : "An Ast is already loaded"
*>
fn GlobalContext*? load_ast(String[] c3c_args, AstSettings settings = {.verbose, .print_stderr}) {
	internal::context.loaded = true;
	context.settings = settings;
	
	Process process = process::spawn({"c3cdev", "build", "--ast-dump"})!;
	defer {
		process.join()!!;
		process.destroy();
	}

	bool failed = false;
	if(catch err = internal::read_dump(&process)) {
		internal::print_verbose("read_dump failed with error: %s", err);
		if(internal::context.segments.size > 0) {
			internal::print_verbose("Most recent segment was %s", internal::context.segments[^1].name());
		}
		internal::print_stderr(&process);
		return err~;
	}

	if(internal::print_stderr(&process)) {
		return C3C_ERROR~;
	}

	return context.global;
}

<*
 @require internal::context.loaded : "No Ast is currently loaded"
*>
fn void free_ast() {
	internal::context.loaded = false;

	foreach(Segment segment : internal::context.segments) {
		posix::munmap(segment.vmem, (usz)segment.vmem_length);
	}
}

fn GlobalContext* gc() => context.global;