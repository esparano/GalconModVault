from keras.models import Sequential
from keras.layers import Dense
from keras.initializers import Constant
import numpy
numpy.random.seed(70)
model = Sequential()
model.add(Dense(2, input_dim=4, kernel_initializer='uniform', activation='relu', use_bias=True, bias_initializer=Constant(0.01)))
print(model.get_weights())
# calculate predictions
a = numpy.array([[1,2,3,4]])
predictions = model.predict(a)
print(predictions)