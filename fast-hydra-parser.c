#include <ctype.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

enum table_fields {
    T_STATUS,
    T_ID,
    T_JOB,
    T_FINISHED_AT,
    T_PKG_NAME,
    T_SYSTEM,
    T_COUNT
};

static
void extract_text(const char *start, const char *end, char *dst, size_t dst_size)
{
    bool in_tag = false;
    size_t j = 0;

    for (const char *p = start; p < end && j + 1 < dst_size; p++) {
        if (*p == '<') { in_tag = true; continue; }
        if (*p == '>') { in_tag = false; continue; }
        if (in_tag) continue;

        dst[j++] = *p;
    }
    dst[j] = '\0';
}

static
void parse_status(const char *start, const char *end, char *dst, size_t dst_size)
{
    const char *p = start;

    // Find <img ... alt="..."
    while (p < end) {
        const char *alt = strstr(p, "alt=\"");
        if (!alt || alt >= end) break;

        alt += 5; // skip 'alt="'
        const char *alt_end = strchr(alt, '"');
        if (!alt_end || alt_end > end) break;

        size_t len = alt_end - alt;
        if (len >= dst_size) len = dst_size - 1;
        strncpy(dst, alt, len);
        dst[len] = '\0';
        return;
    }
}

static
void (*const PARSERS[T_COUNT])(const char *start, const char *end, char *dst, size_t dst_size) =
{
    [T_STATUS] = parse_status,
    [T_ID] = extract_text,
    [T_JOB] = extract_text,
    [T_FINISHED_AT] = extract_text,
    [T_PKG_NAME] = extract_text,
    [T_SYSTEM] = extract_text,
};

static
void cleanup(char *str)
{
    char *out = str;

    for (; *str != '\0'; str++)
        if (!isspace(*str))
            *out++ = *str;
    *out = '\0';
}

static
char *read_input_file(char const *filepath)
{
    char *data = NULL;
    int fd = open(filepath, O_RDONLY);

    if (fd < 0)
        goto failure;

    struct stat st;
    if (fstat(fd, &st) < 0)
        goto failure;

    size_t filesize = st.st_size;
    data = mmap(NULL, filesize, PROT_READ, MAP_PRIVATE, fd, 0);

    if (data == MAP_FAILED) {
failure:
        perror("read_input_file");
    }
ok:
    close(fd);
    return data;
}

int main(int argc, char **argv)
{
    if (argc < 2)
        return fprintf(stderr, "Usage: %s file.html\n", argv[0]), EXIT_FAILURE;

    char *data = read_input_file(argv[1]);

    printf("Status,ID,Job,Finished at,Package/release name,System\n");

    char fields[T_COUNT][1 << 10];

    int field_idx = 0;
    bool in_tr = false;
    char *p = strstr(data, "id=\"tabs-still-fail\"");

#define lengthof(s) (sizeof (s) - 1)
#define sized(s) s, lengthof(s)

    if (p == NULL)
        return EXIT_FAILURE;

    while (*p != '\0') {
        // start of <tr>
        if (!in_tr && strncmp(p, sized("<tr")) == 0) {
            in_tr = true;
            field_idx = 0;
            p += lengthof("<tr");
            continue;
        }

        // end of </tr>
        if (in_tr && strncmp(p, sized("</tr>")) == 0) {
            if (field_idx == T_COUNT) {
                printf("%s,%s,%s,%s,%s,%s\n",
                    fields[T_STATUS],
                    fields[T_ID], fields[T_JOB],
                    fields[T_FINISHED_AT], fields[T_PKG_NAME],
                    fields[T_SYSTEM]);
            }
            in_tr = false;
            p += lengthof("</tr>");
            continue;
        }

        // inside <tr>, detect <td> ... </td>
        if (in_tr && strncmp(p, sized("<td")) == 0) {
            char *td_start = strchr(p, '>');
            if (!td_start) break;
            td_start++; // skip '>'

            char *td_end = strstr(td_start, "</td>");
            if (!td_end) break;

            if (field_idx < T_COUNT) {
                PARSERS[field_idx](td_start, td_end, fields[field_idx], sizeof fields[field_idx]);
                cleanup(fields[field_idx]);
                field_idx++;
            }
            p = td_end + lengthof("</td>");
            continue;
        }

        p++;
    }
}
