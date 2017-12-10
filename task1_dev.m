%% Let's get things started

% Limpeza inicial
close all;  %windows
clc;  %commands
clear;  %workspace

cars = startup; % get every car photo
gndtrus = getGroundTruths; % get every ground truth

similarity = zeros(size(cars,2), size(cars{1},2) + 1);  % sedans have one extra car compared to compacts

% figure; imshow(cars{1}{1})  % cars -> comp_front -> compact1
% type_view = size(cars,2)  % cars rows (16)
% car = size(cars{i},2)  % type_view rows (varia)
% img_rows = size(cars{1}{1},1)
% img_cols = size(cars{1}{1},2)


%% Adaptation to image

% letter_widths = [99-76 655-636 1401-1354 1554-1506];
% letter_widths2 = [54-29 632-610 1380-1333 1536-1487];
% letter_widths3 = [141-119 683-665 1365-1323 1504-1461];
% letter_widths4 = [162-139 678-660 1371-1326 1522-1473];
% letter_widths5 = [53-29 629-610 1380-1332 1534-1486];

% letter_widths = [23 19 47 48];
% letter_widths2 = [25 22 47 49];
% letter_widths3 = [22 18 42 43];
% letter_widths4 = [23 18 45 49];
% letter_widths5 = [24 19 48 48];
% 
% widths_sup = [28 26 54 55];
% widths_inf = [19 14 36 37];
% 
% widths_mid = [23.5 20 45 46];

lw_sup = [28 55];
lw_inf = [14 37];


%% Boundaries

for i = 1:size(cars,2)
    for j = 1:size(cars{i},2)
%         i = 13; j = 4;  %dev
        
        car = cars{i}{j};
%         figure; imshow(car)  %dev
%         title('original');  %dev
            
        car_sides = imclose(car, strel('line', 120, 0));
        car_sides = imgaussfilt(car_sides, 1);
        
        %% left / write coordinates
        
        sum_cols = zeros(1, size(car_sides,2));
        for k = 1:size(car_sides,2)
            sum_cols(k) = sum(car_sides(:,k));
        end
        
        
        [maxima, max_x] = findpeaks(diff(sum_cols));
        [minima, min_x] = findpeaks(diff(-sum_cols));
        
        c1 = 0;
        c2 = 0;
        for k = 1:min(size(maxima,2), size(minima,2))
            if(abs(maxima(k)) < 0.15*max(maxima))
                maxima(k) = 0;
            else
                c1 = c1 + 1;
            end
            if(abs(minima(k)) < 0.15*max(minima))
                minima(k) = 0;
            else
                c2 = c2 + 1;
            end
        end
        
        tmp_max = zeros(1, c1);
        tmp_max_x = zeros(1, c1);
        tmp_min = zeros(1, c2);
        tmp_min_x = zeros(1, c2);
        c1 = 0;
        c2 = 0;
        for k = 1:min(size(maxima, 2), size(minima, 2))
            if(maxima(k) ~= 0)
                c1 = c1 + 1;
                tmp_max(c1) = maxima(k);
                tmp_max_x(c1) = max_x(k);
            end
            if(minima(k) ~= 0)
                c2 = c2 + 1;
                tmp_min(c2) = minima(k);
                tmp_min_x(c2) = min_x(k);
            end
        end
        
        % apagar m�ximos precedidos de m�nimos cuja dist�ncia perfaz a
        % largura de uma letra
        c3 = 0;
        for w = 1:size(tmp_max, 2)
            v = 1;
            while(v <= length(tmp_min_x) && tmp_min_x(v) < tmp_max_x(w))
                dist = tmp_max_x(w) - tmp_min_x(v);
                if((dist <= lw_sup(1) && dist >= lw_inf(1)) || (dist <= lw_sup(2) && dist >= lw_inf(2)))
                    tmp_max(w) = 0;
                    tmp_max_x(w) = 0;
                    tmp_min(v) = 0;
                    tmp_min_x(v) = 0;
                    c3 = c3 + 1;
                end
                v = v + 1;
            end
        end
        
        maxima = zeros(1, c1-c3);
        max_x = zeros(1, c1-c3);
        minima = zeros(1, c2-c3);
        min_x = zeros(1, c2-c3);
        c1 = 0;
        c2 = 0;
        for k = 1:size(tmp_max, 2)
            if(tmp_max(k) ~= 0)
                c1 = c1 + 1;
                maxima(c1) = tmp_max(k);
                max_x(c1) = tmp_max_x(k);
            end
        end
        for k = 1:size(tmp_min, 2)
            if(tmp_min(k) ~= 0)
                c2 = c2 + 1;
                minima(c2) = tmp_min(k);
                min_x(c2) = tmp_min_x(k);
            end
        end
        
        % left
        if(max_x(1) < min_x(1)); left = max_x(1); else; left = min_x(1); end
        
        % right
        if(max_x(length(max_x)) > min_x(length(min_x))); right = max_x(length(max_x)); else; right = min_x(length(min_x)); end
        
        
        
        %% top / bottom

        smoothed = adapthisteq(car);
        smoothed = imgaussfilt(smoothed, 2);
        smoothed = imclose(smoothed, strel('line', 150, 0));
        smoothed = imgaussfilt(smoothed, 7);

        sum_cols = zeros(1, size(smoothed,1));

        for k = 1:size(smoothed,1)
            sum_cols(k) = sum(smoothed(k,:));
        end

        [maxima, max_y] = findpeaks(diff(sum_cols));
        [minima, min_y] = findpeaks(diff(-sum_cols));
        
        c1 = 0;
        c2 = 0;
        for k = 1:min(size(maxima,2), size(minima,2))
            if((abs(maxima(k)) < 0.20*max(maxima)) || (max_y(k) < 0.10*size(car,1)) || (max_y(k) > 0.90*size(car,1)))
                maxima(k) = 0;
            else
                c1 = c1 + 1;
            end
            if((abs(minima(k)) < 0.20*max(minima)) || (min_y(k) < 0.10*size(car,1)) || (min_y(k) > 0.90*size(car,1)))
                minima(k) = 0;
            else
                c2 = c2 + 1;
            end
        end
        
        tmp_max = zeros(1, c1);
        tmp_max_y = zeros(1, c1);
        tmp_min = zeros(1, c2);
        tmp_min_y = zeros(1, c2);
        c1 = 0;
        c2 = 0;
        for k = 1:min(size(maxima, 2), size(minima, 2))
            if((maxima(k) ~= 0) && ((max_y(k) > 0.10*size(car,1)) && (max_y(k) < 0.90*size(car,1))))
                c1 = c1 + 1;
                tmp_max(c1) = maxima(k);
                tmp_max_y(c1) = max_y(k);
            end
            if((minima(k) ~= 0) && ((min_y(k) > 0.10*size(car,1)) && (min_y(k) < 0.90*size(car,1))))
                c2 = c2 + 1;
                tmp_min(c2) = minima(k);
                tmp_min_y(c2) = min_y(k);
            end
        end
        
        % top
        if(tmp_max_y(1) < tmp_min_y(1)); top = tmp_max_y(1); else; top = tmp_min_y(1); end
        
        % bottom
        if(tmp_max_y(length(tmp_max_y)) < tmp_min_y(length(tmp_min_y))); bottom = tmp_max_y(length(tmp_max_y)); else; bottom = tmp_min_y(length(tmp_min_y)); end

        tolerance = [0.15 0.025 0.15 0.05];
        top = top - top*tolerance(1);
        right = right + right*tolerance(2);
        bottom = bottom + bottom*tolerance(3);
        left = left - left*tolerance(4);
        
        car_cropped = zeros(size(car,1), size(car,2));
        for w = 1:size(car,1)
            for v = 1:size(car,2)
                if(~(w < top || w > bottom || v < left || v > right))
                    car_cropped(w,v) = car(w,v);
                else
                    car_cropped(w,v) = 0.5;
                end
            end
        end
        
%         car_cropped = imcrop(car, [left top right-left bottom-top]);
%         car_cropped = imopen(car_cropped, strel('line', 20, 0));
%         figure; imshow(car_cropped)   %dev
%         title('before processing');   %dev

        %% getting it nice and clean

%         smoothed_bounds = imgaussfilt(car_cropped, 20);
%         car_cropped = imopen(car_cropped, strel('disk', 5));

%         for w = 1:size(car,1)
%             for v = 1:size(car,2)
%                 if((w < top || w > bottom || v < left || v > right))
%                     car_cropped(w,v) = smoothed_bounds(w,v);
%                 end
%             end
%         end
        
%         car_cropped = imfilter(car_cropped, fspecial('log', 5, 0.2));

        
        testcar = car_cropped;
        
        car_cropped = edge(testcar, 'Canny', 0.08, 0.7);
%         figure; imshow(car_cropped)
%         title('Canny 0.08 0.7');   %dev
        
        for w = 1:size(car_cropped, 1)
            for v = 1:size(car_cropped, 2)
                if(abs(w-top) < 3 || abs(v-right) < 3 || abs(w-bottom) < 3 || abs(v-left) < 3)
                    car_cropped(w,v) = 0;
                end
            end
        end
        
%         figure; imshow(car_cropped)   %dev
%         title('crop');   %dev
        
        for w = 1:2
            if(w == 1)
                thetas = [-40:-34 34:40 -26:-18 18:26];
            elseif(w == 2)
                thetas = -3:3;
            end

            [H, T, R] = hough(car_cropped, 'Theta', thetas);
    %             figure; imshow(H,[],'XData',T,'YData',R);
    %             xlabel('\theta'), ylabel('\rho');
    %             axis on, axis normal, hold on;
            P = houghpeaks(H, 10);
            lines = houghlines(car_cropped, T, R, P, 'FillGap', 3, 'MinLength', 50);

%             figure, imshow(car_cropped), hold on
            max_len = 0;
            for k = 1:length(lines)
               xy = [lines(k).point1; lines(k).point2];
%                plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

               % Plot beginnings and ends of lines
%                plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%                plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

               % Determine the endpoints of the longest line segment
               len = norm(lines(k).point1 - lines(k).point2);
               if ( len > max_len)
                  max_len = len;
                  xy_long = xy;
               end
            end
    %         plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','cyan');
            if(w == 1)
                old_lines = lines;
            end
        end

        for v = 1:2
            for w = 1:length(lines)
                % Call Bresenham's algorithm
                [x, y] = bresenham(lines(w).point1(1), lines(w).point1(2), ...
                                   lines(w).point2(1), lines(w).point2(2));
                
                for z = 1:length(x)
                    if(x(z) < top*1.2 && x(z) < bottom*0.8 && y(z) > left*1.2 && y(z) < right*0.8)
                        car_cropped(y, x) = 0;
                    end
                end
            end
            lines = old_lines;
        end 

%         figure; imshow(car_cropped)   %dev
%         title('deleted lines');   %dev
        
        car_cropped = bwmorph(car_cropped, 'thin');
%         figure; imshow(car_cropped)   %dev
%         title('thin');   %dev
        
%         car_cropped = bwmorph(car_cropped, 'close');
        car_cropped = imclose(car_cropped, strel('disk', 10));
%         figure; imshow(car_cropped)   %dev
%         title('close');   %dev
        
        car_cropped = imfill(car_cropped, 'holes');
%         figure; imshow(car_cropped)   %dev
%         title('fill');   %dev
        
        car_cropped = imopen(car_cropped, strel('disk', 15));
%         figure; imshow(car_cropped)   %dev
%         title('open');   %dev
        
        
%         for k = 1:5
%             car_cropped = imopen(car_cropped, strel('disk', 25*k));
%             figure; imshow(car_cropped)   %dev
%             title(['open disk ' num2str(k, '%2d')]);   %dev
% 
%             car_cropped = imclose(car_cropped, strel('disk', 20));
%             figure; imshow(car_cropped)   %dev
%             title(['close disk' num2str(k, '%2d')]);   %dev
%         end
        
%         car_cropped = imopen(car_cropped, strel('line', 90, 35));
%         figure; imshow(car_cropped)   %dev
%         title('open 90 35�');   %dev
%         
%         car_cropped = imopen(car_cropped, strel('line', 90, 0));
%         figure; imshow(car_cropped)   %dev
%         title('open 90 0');   %dev
        
        
%         segIm = imbinarize(car_cropped);   %dev
%         segIm = im2bw(car_cropped, 0.01);   %dev
%         figure; imshow(segIm, [])   %dev

        %% Efficiency

        gndtru = gndtrus{i}{j};
        
        similarity(i,j) = 2*nnz(car_cropped&gndtru)/(nnz(car_cropped) + nnz(gndtru));

    end
end

sim_values = similarity(similarity ~= 0);

average_efficiency = mean(sim_values)
