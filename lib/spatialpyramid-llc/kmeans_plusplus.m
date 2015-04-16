% given a data matrix MxN, compute the initial kmeans cluster centers
% using the k-means++ algorithm (intelligently pick initial centers that are maximally far away)
% Returns: the k initial cluster centers for initializing k-means

%reference:
% D. Arthur and S. Vassilvitskii, "k-means++: The Advantages of
%       Careful Seeding", Technical Report 2006-13, Stanford InfoLab, 2006.

function [initial_centers] = kmeans_plusplus(data, k)

fprintf('Running k-means++ \n');
fprintf('Initial Center %d out of %d\n', 1, k);
initial_centers = nan(k,size(data,2));
initial_center = randperm(size(data,1) , 1); % pick random first center
initial_centers(1,:) = data(initial_center, :); % add first to list
%data(initial_center, :) = []; % remove from set

for i=2:k
    fprintf('Initial Center %d out of %d\n', i, k);
    current_dists = min(sp_dist2(data, initial_centers(i-1,:)), [], 2); % compute distance^2 to nearest existing center
    weights = current_dists ./ sum(current_dists);
    new_center_index = datasample(1:size(data,1), 1, 2, 'Weights', weights');
    initial_centers(i,:) = data(new_center_index, :); % add center to list
    %data(new_center_index, :) = []; % remove from set
end
