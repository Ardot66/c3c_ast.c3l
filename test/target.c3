module test_target;

fn int main() @tag("test_target_tag", "value") {
	int test = 1;
	if(test == 2) {
		return 1;
	}
	return 0;
}