extends Node

# This class was written in part by ChatGPT, thus, bad variable names.
# This class was edited and stitched together by a human, thus, worse variable names.

const Matrix = preload('res://common/matrix.gd')

var rows: int
var cols: int
var data: Array

# Constructor
func _init(rows: int, cols: int):
	self.rows = rows
	self.cols = cols
	self.data = Array()
	
	for i in range(rows):
		data.append([])
		for j in range(cols):
			data[i].append(0)

# Set row values
func set_row(row_index: int, values: Array):
	data[row_index - 1] = values



func append_col(col : Array):
	data[rows] = col
	cols += 1;



func append_row(row : Array):
	for i in range( rows ):
		data[i][cols] = row[i]
	rows += 1;



func row_sum() -> Array:
	var sum = []; 
	sum.resize( cols );
	
	for i in range( rows ):
		for j in range( cols ):
			sum[j] += data[i][j];
	return sum;



# Set column values
func set_col(col_index: int, values: Array):
	for i in range(rows):
		data[i][col_index - 1] = values[i]



func get_element(row_index, col_index):
	return data[row_index - 1][col_index - 1]



func set_element(row_index, col_index, contents):
	data[row_index - 1][col_index - 1] = contents;



func multiply_rows_by_row(row: Array):
	for i in range(rows):
		for j in range(cols):
			data[i][j] *= row[j]



func multiply_cols_by_col(col: Array):
	for i in range(rows):
		for j in range(cols):
			data[i][j] *= col[i]



func matrix_multiply( a:Matrix, b:Matrix ):
	
	if !(a.rows == b.columns):
		return null
	
	var cell = 0;
	
	var product = Matrix.new(a.rows, b.columns)
	for i in range(a.rows):
		for j in range(b.columns):
			for n in range(b.rows):
				cell += a.get_element(i,n) * b.get_element(n,j)
			product.set_element(i,j,cell)
			cell = 0;
	#return [[sum(x*y for x,y in zip(row,col)) for col in zip(*b)] for row in a]





# Determinant
# Recursive, by removing row
#func determinant():
#	pass
