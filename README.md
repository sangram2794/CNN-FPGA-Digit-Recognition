# CNN-FPGA-Digit-Recognition
Handwritten digit recognition using CNN on DE2 115 FPGA board

-trained the CNN model using python (MNIST dataset) on my computer


-pleaced the .mem files generated (weights) in the same folder as my quartus project

-8 different modules with top_cnn.v as the main module.


-predicted digit is displaced on the 7 segment display on the FPGA board, and the LED0 glows when the operation is done (KEY[0] to rst everything, KEY[1] to start the inferencing)

<img width="1245" height="645" alt="Screenshot 2026-03-12 184248" src="https://github.com/user-attachments/assets/20b7289e-02ed-4641-8679-ad5c5701ba9b" />

RTL View

<img width="1848" height="453" alt="image" src="https://github.com/user-attachments/assets/d1ffed2a-139c-4f6f-83fb-ca9d917db059" />

Outputs
Test1: Digit 3
<img width="965" height="570" alt="image" src="https://github.com/user-attachments/assets/47786206-e55f-4874-8dea-a29ae43f8759" />

Test2: Digit 9
<img width="837" height="735" alt="image" src="https://github.com/user-attachments/assets/5e31625d-f0c1-4e40-a7e0-4a6a7cd122ef" />

Test3: Digit 1
<img width="821" height="623" alt="image" src="https://github.com/user-attachments/assets/6615cb45-0678-43a9-ad42-fbb93bcfc613" />
