import numpy

image_data = numpy.random.randint( #Realistic images would be much larger
    low=100, high=14000, size=(1, 5, 5)).astype(numpy.uint16)

display_min = 1000
display_max = 10000.0

print(image_data)
threshold_image = ((image_data.astype(float) - display_min) *
                   (image_data > display_min))
print(threshold_image)
scaled_image = (threshold_image * (255. / (display_max - display_min)))
scaled_image[scaled_image > 255] = 255
print(scaled_image)
display_this_image = scaled_image.astype(numpy.uint8)
print(display_this_image)