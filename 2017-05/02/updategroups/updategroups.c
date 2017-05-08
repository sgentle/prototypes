#include <stdlib.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>

int main() {
	struct passwd *pwd = getpwuid(getuid());
	if (pwd == NULL) {
		perror("getpwuid");
		exit(EXIT_FAILURE);
	}
	
	int numgroups = 0;

	if (getgrouplist(pwd->pw_name, pwd->pw_gid, NULL, &numgroups) != -1) {
		exit(EXIT_FAILURE);
	}

        gid_t *groups = malloc(numgroups * sizeof (gid_t));
	if (groups == NULL) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	if (getgrouplist(pwd->pw_name, pwd->pw_gid, groups, &numgroups) < 0) {
		exit(EXIT_FAILURE);
	}
	
	if (setgroups(numgroups, groups) < 0) {
		perror("setgroups");
		exit(EXIT_FAILURE);
	}
}
