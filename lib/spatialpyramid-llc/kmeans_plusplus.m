%% K-mean++ algorithm for choosing intelligent initial K-means centers
% Reference:
% D. Arthur and S. Vassilvitskii, "k-means++: The Advantages of
%       Careful Seeding", Technical Report 2006-13, Stanford InfoLab, 2006.
%
% Ke Ma & Chris Bodden
%
% Inputs:
%   data - N x D matrix of SIFT features for training images
%   k - the codebook size (number of centers)
% Outputs:
%   initial_centers - k x D matrix of initial centers to seed K-means
%   algorithm

function [initial_centers] = kmeans_plusplus(data, k)

fprintf('Running k-means++ \n');
fprintf('Initial Center %d out of %d\n', 1, k);
initial_centers = nan(k,size(data,2));
initial_center = randperm(size(data,1) , 1); % pick random first center
initial_centers(1,:) = data(initial_center, :); % add first to list

for i=2:k
    fprintf('Initial Center %d out of %d\n', i, k);
    current_dists = min(sp_dist2(data, initial_centers(i-1,:)), [], 2); % compute distance^2 to nearest existing center
    weights = current_dists ./ sum(current_dists);
    new_center_index = datasample(1:size(data,1), 1, 2, 'Weights', weights');
    initial_centers(i,:) = data(new_center_index, :); % add center to list
end
