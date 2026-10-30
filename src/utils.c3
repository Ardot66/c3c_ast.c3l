module ardot::c3c::ast;
import c3c;
import std::io;

struct VecHeader {
	int size;
	int capacity;
	char[*] data;
}

fn VecHeader* vec_header(void* vec) @local {
	return vec - VecHeader::size;
}

fn int vec_size(void* vec) {
	return vec_header(vec).size;
}

<*
 @require $Typeof(vec)::kind == POINTER &&& $Typeof(vec)::inner.kind == POINTER : "The passed vector must be a pointer to a pointer."
*>
macro @vec_foreach(vec; @body(element)) {
	if(vec == null) {
		return;
	}

	sz size = vec_size(vec);
	for(sz i = 0; i < size; i++) {
		@body(vec[i]);
	}
}

fn Ast* ast_ptr(AstId id) => id == 0 ? null : context.ast_arena + id;
fn Expr* expr_ptr(ExprId id) => id == 0 ? null : context.expr_arena + id;
fn Decl* decl_ptr(DeclId id) => id == 0 ? null : context.decl_arena + id;
fn TypeInfo* type_info_ptr(TypeInfoId id) => id == 0 ? null : context.type_info_arena + id;
fn SourceLoc* source_loc_ptr(SourceLocId id) => id == 0 ? null : context.source_loc_arena + id;

fn void* HTable.get(&self, void *key)
{
	uint idx = (uint)((((uptr)key) ^ ((uptr)key) >> 8) & self.mask);
	HTEntry *entry = self.entries[idx];
	if (!entry) return null;
	do
	{
		if (entry.key == key) return entry.value;
		entry = entry.next;
	} while (entry);
	return null;
}

fn String SourceLoc.get_content(&self) {
	c3c::File* file = context.global.loaded_sources[self.file_id];
	return (String)file.contents[self.offset..self.offset + self.length];
}

fn sz? SourceLoc.to_format(&self, Formatter* f) @dynamic {
	return f.print(self.get_content());
}

fn String c_string(CChar* c_string) => ((ZString)c_string).str_view();

<*
 @require $Typeof(value)::kind == CONSTDEF
*>
macro String const_name(value) {
	$foreach $i, $value : $Typeof(value)::values:
		if(value == $value) {
			return $Typeof(value)::names[$i];
		}
	$endforeach
	return "INVALID_CONST_VALUE";
}