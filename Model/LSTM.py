import numpy as np
import pandas as pd
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dropout, Dense
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# Load your data from the Excel file
data_path = '/Users/liuyang/PycharmProjects/InsoleGetData/Walk_SPHERE.xlsx'
data = pd.read_excel(data_path)

# Check the first few rows to understand the structure
print(data.head())

# Calculate the magnitude and add it to the dataset
data['magnitude'] = np.sqrt(data['x'] ** 2 + data['y'] ** 2 + data['z'] ** 2)

# Extract relevant columns
X = data[['x', 'y', 'z', 'magnitude']].values
y = data['name'].values

# Encode labels
label_encoder = LabelEncoder()
y_encoded = label_encoder.fit_transform(y)
y_one_hot = to_categorical(y_encoded)  # One-hot encode the labels

# Define the sequence length (timesteps) and number of features
timesteps = 4  # Adjust according to your data and needs
n_features = 4  # Number of features: x, y, z, magnitude


# Prepare sequences and labels
def create_sequences(data, labels, timesteps):
    X_sequences = []
    y_sequences = []

    for i in range(len(data) - timesteps + 1):
        end_ix = i + timesteps
        if end_ix > len(data):
            break
        seq_x = data[i:end_ix]
        seq_y = labels[end_ix - 1]  # Use the label at the end of the sequence
        X_sequences.append(seq_x)
        y_sequences.append(seq_y)

    return np.array(X_sequences), np.array(y_sequences)


# Create sequences
X_sequences, y_sequences = create_sequences(X, y_one_hot, timesteps)

# Split the data into training and test sets
X_train, X_test, y_train, y_test = train_test_split(X_sequences, y_sequences, test_size=0.2, random_state=42)

# Define the model
model = Sequential()
model.add(LSTM(64, input_shape=(timesteps, n_features)))
model.add(Dropout(0.5))
model.add(Dense(y_sequences.shape[1], activation='softmax'))  # Output size should match the number of classes

# Compile the model
model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# Train the model
history = model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))

# Evaluate the model
loss, accuracy = model.evaluate(X_test, y_test)
print(f'Test accuracy: {accuracy}')

# Optionally, plot the training history
import matplotlib.pyplot as plt

plt.plot(history.history['accuracy'], label='accuracy')
plt.plot(history.history['val_accuracy'], label='val_accuracy')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.ylim([0, 1])
plt.legend(loc='lower right')
plt.show()

