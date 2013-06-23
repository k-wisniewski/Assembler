#include <stdio.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>

#define MICRO_MULTIPLIER  0xF4240
#define SSE_WIDTH         0x10
#define BOARD_BASE_WIDTH  0x32
#define BOARD_BASE_HEIGHT 0x3c
#ifdef  SSE
#define BOARD_WIDTH       (BOARD_BASE_WIDTH + SSE_WIDTH + 1)
#else
#define BOARD_WIDTH       (BOARD_BASE_WIDTH + 2)
#endif
#define BOARD_HEIGHT      (BOARD_BASE_HEIGHT + 2)
#define CLOCK_DIV         0x3e8

typedef char   BoardCell;

void zeroRestOfData(BoardCell *board, BoardCell *copy)
{
    int j;
    size_t alloc_leftover, offset;
    alloc_leftover = (BOARD_WIDTH - BOARD_BASE_WIDTH - 1) * sizeof(BoardCell);
    offset = (1 + BOARD_BASE_WIDTH) * sizeof(BoardCell);

    memset(copy, 0, BOARD_WIDTH * BOARD_HEIGHT * sizeof(BoardCell));
    memset(board, 0, BOARD_WIDTH * sizeof(BoardCell));
    for (j = 0; j <= BOARD_BASE_HEIGHT + 1; j++)
    {
        *(board + BOARD_WIDTH * j) = 0;
    }
    memset(board + BOARD_WIDTH * (BOARD_BASE_HEIGHT + 1), 0, BOARD_WIDTH * sizeof(BoardCell));
}

void play_simulation(BoardCell **board, BoardCell **copy, int iterations)
{
    int i, j, k;
#ifndef PRINT_FRAME
    double secs;
    clock_t start = clock();
#endif

    for (i = 0; i < iterations; i++)
    {
        make_simulation(board, copy);
#ifdef PRINT_FRAME
        printf("---------------------------------- iteration: %d -------------------------------\n", (i + 1));
        save_simulation(*board);
        sleep(2);
#endif
        zeroRestOfData(*board, *copy);
    }
#ifndef PRINT_FRAME

    secs = (clock() - start) /(double) CLOCKS_PER_SEC;
    fprintf(stderr, "Time taken %f seconds\n", secs);
#endif
}

int save_simulation(BoardCell *board)
{
    int i, j;

    for (i = 1; i <= BOARD_BASE_HEIGHT; ++i)
    {
        for (j = 1; j <= BOARD_BASE_WIDTH; ++j)
        {
            printf("%hhu", board[i * BOARD_WIDTH + j]);
        }
        printf("\n");
    }

    return 0;
}

int load_simulation(BoardCell *board, BoardCell *copy)
{
    int i, j;

    memset(board, 0, BOARD_HEIGHT * BOARD_WIDTH * sizeof(BoardCell));
    memset(copy, 0,  BOARD_HEIGHT * BOARD_WIDTH * sizeof(BoardCell));
    for (i = 1; i <= BOARD_BASE_HEIGHT; ++i)
    {
        for (j = 1; j <= BOARD_BASE_WIDTH; ++j)
        {
            scanf("%c", &(board[i * BOARD_WIDTH + j]));
            board[i * BOARD_WIDTH + j] -= '0';
        }
        scanf("\n");
    }

    return 0;
}

int main(int argc, char *argv[])
{
    BoardCell board[BOARD_HEIGHT * BOARD_WIDTH];
    BoardCell copy[BOARD_HEIGHT * BOARD_WIDTH];
    BoardCell *boardPtr = board, *copyPtr = copy;
    int iterations = 0;
    if (argc < 2)
    {
        printf("You must specify number of generations to be calculated!\n");
        return 1;
    }

    check_compatibility();
    iterations = atoi(argv[1]);
    load_simulation(board, copy);
    play_simulation(&boardPtr, &copyPtr, iterations);
#ifndef PRINT_FRAME
    save_simulation(boardPtr);
#endif
    return 0;
}

