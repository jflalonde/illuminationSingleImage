#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <errno.h>

/*
 * Optimize LSVM objective function via gradient descent.
 *
 * We use an adaptive cache mechanism.  After a negative example
 * scores beyond the margin multiple times it is removed from the
 * training set for a fixed number of iterations.
 */

// Data File Format
// EXAMPLE*
// 
// EXAMPLE:
//  long label          ints
//  blocks              int
//  dim                 int
//  DATA{blocks}
//
// DATA:
//  block label         float
//  block data          floats
//
// Internal Binary Format
//  len           int (byte length of EXAMPLE)
//  EXAMPLE       <see above>
//  unique flag   byte

// number of iterations
#define ITER 5000000

// small cache parameters
#define INCACHE 3
#define WAIT 10

// error checking
#define check(e) \
(e ? (void)0 : (printf("%s:%u error: %s\n%s\n", __FILE__, __LINE__, #e, strerror(errno)), exit(1)))

// number of non-zero blocks in example ex
#define NUM_NONZERO(ex) (((int *)ex)[labelsize+1])

// float pointer to data segment of example ex
#define EX_DATA(ex) ((float *)(ex + sizeof(int)*(labelsize+3)))

// class label (+1 or -1) for the example
#define LABEL(ex) (((int *)ex)[1])

// block label (converted to 0-based index)
#define BLOCK_IDX(data) (((int)data[0])-1)

int labelsize;
int dim;

// comparison function for sorting examples 
int comp(const void *a, const void *b) {
  // sort by extended label first, and whole example second...
  int c = memcmp(*((char **)a) + sizeof(int), 
		 *((char **)b) + sizeof(int), 
		 labelsize*sizeof(int));
  if (c)
    return c;
  
  // labels are the same  
  int alen = **((int **)a);
  int blen = **((int **)b);
  if (alen == blen)
    return memcmp(*((char **)a) + sizeof(int), 
		  *((char **)b) + sizeof(int), 
		  alen);
  return ((alen < blen) ? -1 : 1);
}

// a collapsed example is a sequence of examples
struct collapsed {
  char **seq;
  int num;
};

// set of collapsed examples
struct data {
  collapsed *x;
  int num;
  int numblocks;
  int *blocksizes;
  float *regmult;
  float *learnmult;
};

// seed the random number generator with the current time
void seed_time() {
 struct timeval tp;
 check(gettimeofday(&tp, NULL) == 0);
 srand48((long)tp.tv_usec);
}

static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }

// gradient descent
void gd(double C, double J, data X, double **w, double **lb) {
  int num = X.num;
  
  // state for random permutations
  int *perm = (int *)malloc(sizeof(int)*X.num);
  check(perm != NULL);

  // state for small cache
  int *W = (int *)malloc(sizeof(int)*num);
  check(W != NULL);
  for (int j = 0; j < num; j++)
    W[j] = 0;

  int t = 0;
  while (t < ITER) {
    // pick random permutation
    for (int i = 0; i < num; i++)
      perm[i] = i;
    for (int swapi = 0; swapi < num; swapi++) {
      int swapj = (int)(drand48()*(num-swapi)) + swapi;
      int tmp = perm[swapi];
      perm[swapi] = perm[swapj];
      perm[swapj] = tmp;
    }

    // count number of examples in the small cache
    int cnum = 0;
    for (int i = 0; i < num; i++) {
      if (W[i] <= INCACHE)
	cnum++;
    }

    for (int swapi = 0; swapi < num; swapi++) {
      // select example
      int i = perm[swapi];
      collapsed x = X.x[i];

      // skip if example is not in small cache
      if (W[i] > INCACHE) {
	W[i]--;
	continue;
      }

      // learning rate
      double T = t + 1000.0;
      double rateX = cnum * C / T;
      double rateR = 1.0 / T;

      if (t % 10000 == 0) {
	printf(".");
	fflush(stdout);
      }
      t++;
      
      // compute max over latent placements
      int M = -1;
      double V = 0;
      for (int m = 0; m < x.num; m++) {
	double val = 0;
	char *ptr = x.seq[m];
	float *data = EX_DATA(ptr);
	int blocks = NUM_NONZERO(ptr);
	for (int j = 0; j < blocks; j++) {
	  int b = BLOCK_IDX(data);
	  data++;
	  for (int k = 0; k < X.blocksizes[b]; k++)
	    val += w[b][k] * data[k];
	  data += X.blocksizes[b];
	}
	if (M < 0 || val > V) {
	  M = m;
	  V = val;
	}
      }
      
      // update model
      for (int j = 0; j < X.numblocks; j++) {
	double mult = rateR * X.regmult[j] * X.learnmult[j];
	for (int k = 0; k < X.blocksizes[j]; k++) {
	  w[j][k] -= mult * w[j][k];
	}
      }
      char *ptr = x.seq[M];
      int label = LABEL(ptr);
      if (label * V < 1.0) {
	W[i] = 0;
	float *data = EX_DATA(ptr);
	int blocks = NUM_NONZERO(ptr);
	for (int j = 0; j < blocks; j++) {
	  int b = BLOCK_IDX(data);
	  double mult = (label > 0 ? J : -1) * rateX * X.learnmult[b];      
	  data++;
	  for (int k = 0; k < X.blocksizes[b]; k++)
	    w[b][k] += mult * data[k];
	  data += X.blocksizes[b];
	}
      } else if (label == -1) {
	if (W[i] == INCACHE)
	  W[i] = WAIT;
	else
	  W[i]++;
      }
    }

    // apply lowerbounds
    for (int j = 0; j < X.numblocks; j++) {
      for (int k = 0; k < X.blocksizes[j]; k++) {
	w[j][k] = max(w[j][k], lb[j][k]);
      }
    }

  }

  free(perm);
  free(W);
}

// score examples
double *score(data X, char **examples, int num, double **w) {
  double *s = (double *)malloc(sizeof(double)*num);
  check(s != NULL);
  for (int i = 0; i < num; i++) {
    s[i] = 0.0;
    float *data = EX_DATA(examples[i]);
    int blocks = NUM_NONZERO(examples[i]);
    for (int j = 0; j < blocks; j++) {
      int b = BLOCK_IDX(data);
      data++;
      for (int k = 0; k < X.blocksizes[b]; k++)
        s[i] += w[b][k] * data[k];
      data += X.blocksizes[b];
    }
  }
  return s;  
}

// merge examples with identical labels
void collapse(data *X, char **examples, int num) {
  collapsed *x = (collapsed *)malloc(sizeof(collapsed)*num);
  check(x != NULL);
  int i = 0;
  x[0].seq = examples;
  x[0].num = 1;
  for (int j = 1; j < num; j++) {
    if (!memcmp(x[i].seq[0]+sizeof(int), examples[j]+sizeof(int), 
		labelsize*sizeof(int))) {
      x[i].num++;
    } else {
      i++;
      x[i].seq = &(examples[j]);
      x[i].num = 1;
    }
  }
  X->x = x;
  X->num = i+1;  
}

int main(int argc, char **argv) {  
  seed_time();
  int count;
  data X;

  // command line arguments
  check(argc == 8);
  double C = atof(argv[1]);
  double J = atof(argv[2]);
  char *hdrfile = argv[3];
  char *datfile = argv[4];
  char *modfile = argv[5];
  char *inffile = argv[6];
  char *lobfile = argv[7];

  // read header file
  FILE *f = fopen(hdrfile, "rb");
  check(f != NULL);
  int header[3];
  count = fread(header, sizeof(int), 3, f);
  check(count == 3);
  int num = header[0];
  labelsize = header[1];
  X.numblocks = header[2];
  X.blocksizes = (int *)malloc(X.numblocks*sizeof(int));
  count = fread(X.blocksizes, sizeof(int), X.numblocks, f);
  check(count == X.numblocks);
  X.regmult = (float *)malloc(sizeof(float)*X.numblocks);
  check(X.regmult != NULL);
  count = fread(X.regmult, sizeof(float), X.numblocks, f);
  check(count == X.numblocks);
  X.learnmult = (float *)malloc(sizeof(float)*X.numblocks);
  check(X.learnmult != NULL);
  count = fread(X.learnmult, sizeof(float), X.numblocks, f);
  check(count == X.numblocks);
  check(num != 0);
  fclose(f);
  printf("%d examples with label size %d and %d blocks\n",
	 num, labelsize, X.numblocks);
  printf("block size, regularization multiplier, learning rate multiplier\n");
  dim = 0;
  for (int i = 0; i < X.numblocks; i++) {
    dim += X.blocksizes[i];
    printf("%d, %.2f, %.2f\n", X.blocksizes[i], X.regmult[i], X.learnmult[i]);
  }

  // read examples
  f = fopen(datfile, "rb");
  check(f != NULL);
  printf("Reading examples\n");
  char **examples = (char **)malloc(num*sizeof(char *));
  check(examples != NULL);
  for (int i = 0; i < num; i++) {
    // we use an extra byte in the end of each example to mark unique
    // we use an extra int at the start of each example to store the 
    // example's byte length (excluding unique flag and this int)
    int buf[labelsize+2];
    count = fread(buf, sizeof(int), labelsize+2, f);
    check(count == labelsize+2);
    // byte length of an example's data segment
    int len = sizeof(int)*(labelsize+2) + sizeof(float)*buf[labelsize+1];
    // memory for data, an initial integer, and a final byte
    examples[i] = (char *)malloc(sizeof(int)+len+1);
    check(examples[i] != NULL);
    // set data segment's byte length
    ((int *)examples[i])[0] = len;
    // set the unique flag to zero
    examples[i][sizeof(int)+len] = 0;
    // copy label data into example
    for (int j = 0; j < labelsize+2; j++)
      ((int *)examples[i])[j+1] = buf[j];
    // read the rest of the data segment into the example
    count = fread(examples[i]+sizeof(int)*(labelsize+3), 1, 
		  len-sizeof(int)*(labelsize+2), f);
    check(count == len-sizeof(int)*(labelsize+2));
  }
  fclose(f);
  printf("done\n");

  // sort
  printf("Sorting examples\n");
  char **sorted = (char **)malloc(num*sizeof(char *));
  check(sorted != NULL);
  memcpy(sorted, examples, num*sizeof(char *));
  qsort(sorted, num, sizeof(char *), comp);
  printf("done\n");

  // find unique examples
  int i = 0;
  int len = *((int *)sorted[0]);
  sorted[0][sizeof(int)+len] = 1;
  for (int j = 1; j < num; j++) {
    int alen = *((int *)sorted[i]);
    int blen = *((int *)sorted[j]);
    if (alen != blen || 
	memcmp(sorted[i] + sizeof(int), sorted[j] + sizeof(int), alen)) {
      i++;
      sorted[i] = sorted[j];
      sorted[i][sizeof(int)+blen] = 1;
    }
  }
  int num_unique = i+1;
  printf("%d unique examples\n", num_unique);

  // collapse examples
  collapse(&X, sorted, num_unique);
  printf("%d collapsed examples\n", X.num);

  // initial model
  double **w = (double **)malloc(sizeof(double *)*X.numblocks);
  check(w != NULL);
  f = fopen(modfile, "rb");
  for (int i = 0; i < X.numblocks; i++) {
    w[i] = (double *)malloc(sizeof(double)*X.blocksizes[i]);
    check(w[i] != NULL);
    count = fread(w[i], sizeof(double), X.blocksizes[i], f);
    check(count == X.blocksizes[i]);
  }
  fclose(f);

  // lower bounds
  double **lb = (double **)malloc(sizeof(double *)*X.numblocks);
  check(lb != NULL);
  f = fopen(lobfile, "rb");
  for (int i = 0; i < X.numblocks; i++) {
    lb[i] = (double *)malloc(sizeof(double)*X.blocksizes[i]);
    check(lb[i] != NULL);
    count = fread(lb[i], sizeof(double), X.blocksizes[i], f);
    check(count == X.blocksizes[i]);
  }
  fclose(f);
  
  // train
  printf("Training");
  gd(C, J, X, w, lb);
  printf("done\n");

  // save model
  printf("Saving model\n");
  f = fopen(modfile, "wb");
  check(f != NULL);
  for (int i = 0; i < X.numblocks; i++) {
    count = fwrite(w[i], sizeof(double), X.blocksizes[i], f);
    check(count == X.blocksizes[i]);
  }
  fclose(f);

  // score examples
  printf("Scoring\n");
  double *s = score(X, examples, num, w);

  // Write info file
  printf("Writing info file\n");
  f = fopen(inffile, "w");
  check(f != NULL);
  for (int i = 0; i < num; i++) {
    int len = ((int *)examples[i])[0];
    // label, score, unique flag
    count = fprintf(f, "%d\t%f\t%d\n", ((int *)examples[i])[1], s[i], 
                    (int)examples[i][sizeof(int)+len]);
    check(count > 0);
  }
  fclose(f);
  
  printf("Freeing memory\n");
  for (int i = 0; i < X.numblocks; i++) {
    free(w[i]);
    free(lb[i]);
  }
  free(w);
  free(lb);
  free(s);
  for (int i = 0; i < num; i++)
    free(examples[i]);
  free(examples);
  free(sorted);
  free(X.x);
  free(X.blocksizes);
  free(X.regmult);
  free(X.learnmult);

  return 0;
}
