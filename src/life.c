#include <stdio.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>

#define SIMULATION_DIM      0x2
#define ROWS                0x0
#define COLS                0x1

typedef char** Board;
typedef char*  BoardRow;
typedef char   BoardCell;

void free_board(int *size, Board *board)
{
    int i;
    if (*board != NULL)
    {
        for (i = 0; i < (size[ROWS] + 2); ++i)
        {
            if (board[i] != NULL)
            {
                free((*board)[i]);
                (*board)[i] = NULL;
            }
        }
        free((*board));
    }
}

int alloc_board(int *size, Board *board)
{
    int i;
    if ((*board = (Board)malloc((size[ROWS] + 2) * sizeof(BoardRow))) == NULL)
    {
        return 1;
    }

    for (i = 0; i < (size[ROWS] + 2); ++i)
    {
        if (((*board)[i] = malloc((size[COLS] + 2) * sizeof(BoardCell))) == NULL)
        {
            return 1;
        }
        memset((*board)[i], 0, (size[COLS] + 2) * sizeof(BoardCell));
    }
}

//int nbr_from(int *size, Board board, int i, int j)
//{
//    if (i == -1)
//    {
//        i = size[ROWS] - 1;
//    }
//
//    if (j == -1)
//    {
//        j = size[COLS] - 1;
//    }
//
//    if (i == size[ROWS])
//    {
//        i = 0;
//    }
//
//    if (j == size[COLS])
//    {
//        j = 0;
//    }
//
//    return board[i][j];
//}

//void make_simulation(int *size, Board *board, Board *copy)
//{
//    int i;
//    int no_of_nbrs;
//    Board tmp;
//    for (i = 0; i < size[ROWS]; i++)
//    {
//        for(j = 0; j < size[COLS]; j++)
//        {
//            no_of_nbrs = 0;
//            no_of_nbrs += nbr_from(size, *board, i - 1, j - 1);
//            no_of_nbrs += nbr_from(size, *board, i - 1, j);
//            no_of_nbrs += nbr_from(size, *board, i - 1, j + 1);
//            no_of_nbrs += nbr_from(size, *board, i, j - 1);
//            no_of_nbrs += nbr_from(size, *board, i, j + 1);
//            no_of_nbrs += nbr_from(size, *board, i + 1, j - 1);
//            no_of_nbrs += nbr_from(size, *board, i + 1, j);
//            no_of_nbrs += nbr_from(size, *board, i + 1, j + 1);
//            if (((*board)[i][j] && (no_of_nbrs < 2 || no_of_nbrs > 3))
//                    || (!(*board)[i][j] && no_of_nbrs == 3))
//            {
//                printf("no_of_nbrs: %d, i: %d, j: %d\n", no_of_nbrs, i, j);
//                (*copy)[i][j] = !(*board)[i][j];
//            }
//            else
//            {
//                (*copy)[i][j] = (*board)[i][j];
//            }
//        }
//    }
//    tmp = *board;
//    *board = *copy;
//    *copy = tmp;
//}

void play_game(int *size, Board *board, Board *copy, int iterations)
{
    int i, j, k;
    long long msec;
    clock_t start, elapsed_time = 0;
    for (i = 0; i < iterations; i++)
    {
        start = clock();
        make_simulation(size, board, copy);
        elapsed_time += (clock() - start);
        for (j = 1; j <= size[ROWS]; j++)
        {
            for(k = 1; k <= size[COLS]; k++)
            {
                (*copy)[j][k] = 0;
            }
        }
    }
    msec = elapsed_time * 1000 / CLOCKS_PER_SEC;
    printf("Time taken %lld seconds %lld milliseconds\n", msec / 1000, msec % 1000);
}

int save_game(int *size, int iterations, Board board)
{
    int i, j;

    for (i = 1; i <= size[ROWS]; ++i)
    {
        for (j = 1; j <= size[COLS]; ++j)
        {
            printf("%d", board[i][j]);
        }
        printf("\n");
    }

    return 0;
}

int load_game(int *size, Board *board, Board *copy)
{
    char *buf = NULL;
    int i, j;
    size_t buf_size;

    getline(&buf, &buf_size, stdin);
    sscanf(buf, "%d\n", &(size[ROWS]));
    getline(&buf, &buf_size, stdin);
    sscanf(buf, "%d\n", &(size[COLS]));

    alloc_board(size, board);
    alloc_board(size, copy);
    for (i = 1; i <= size[ROWS]; ++i)
    {
        for (j = 1; j <= size[COLS]; ++j)
        {
            scanf("%c", &((*board)[i][j]));
            (*board)[i][j] -= '0';
        }
        scanf("\n");
    }

    return 0;
}
void print_board(int *size, Board board)
{
    int i, j;
    char row = 'a';
    char col = 1;

    printf("  ");
    for (j = 1; j < size[COLS]; ++j)
    {
        printf("%d", col);
        printf(col < 10 ? "_" : "");
        col++;
    }

    printf("\n");

    for (i = 1; i <= size[ROWS]; ++i)
    {
        printf("%c|", row);
        for (j = 1; j <= size[COLS]; ++j)
        {
            printf(board[i][j] ? "x|" : "_|");
        }
        printf("\n");
        row++;
    }
}

int main(int argc, char *argv[])
{
    Board board = NULL;
    Board copy = NULL;
    int size[SIMULATION_DIM];
    int iterations = 0;
    if (argc < 2)
    {
        printf("You must specify number of generations to be calculated!\n");
        return 1;
    }

    iterations = atoi(argv[1]);
    memset(size, 0, SIMULATION_DIM * sizeof(int));
    load_game(size, &board, &copy);
    play_game(size, &board, &copy, iterations);
    save_game(size, iterations, board);
    return 0;
}

