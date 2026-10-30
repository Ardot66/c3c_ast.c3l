module tests;
import ardot::c3c;
import c3c;
import std::io;

const String C3C_PATH = "c3cdev";

fn void test() @test {
	ast::load_ast({C3C_PATH, "build", "test-target", "--ast-dump"})!!;
	defer ast::free_ast();

	Module* this_module;
	ast::@vec_foreach(ast::context.global.module_list; Module* mod) {
		if(((ZString)mod.name.module_field).str_view() == "test_target") {
			this_module = mod;
		}
	};

	test::ne(this_module, null);
	test::eq(ast::vec_size(this_module.units), 1);
	ast::@vec_foreach(this_module.units; CompilationUnit* unit) {
		test::eq(ast::vec_size(unit.functions), 1);

		ast::@vec_foreach(unit.functions; Decl* decl) {
			if(ast::c_string(decl.type.name) == "main") {
				FuncDecl* func = &decl.func_decl;
				AstCompoundStmt* body = &ast::ast_ptr(func.body).compound_stmt;
				Ast* current = ast::ast_ptr(body.first_stmt);

				AstKind[3] kinds = {AST_DECLARE_STMT, AST_IF_STMT, AST_RETURN_STMT};
				sz i = 0;
				while(current != null) {
					test::le(i, kinds.len);
					test::eq(kinds[i], current.ast_kind);
					current = ast::ast_ptr(current.next);
					i += 1;
				}

				test::ne(decl.attrs_resolved, null);
				Expr* tag_expr = decl.attrs_resolved.tags[0].exprs[0];
				test::eq((String)tag_expr.const_expr.bytes.ptr[..tag_expr.const_expr.bytes.len - 1], "test_target_tag");
			}
		};
	};
}