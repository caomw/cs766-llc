% given a data matrix MxN, compute the initial kmeans cluster centers
% using the k-means++ algorithm (intelligently pick initial centers that are maximally far away)
% Returns: the k initial cluster centers for initializing k-means

%reference:
% D. Arthur and S. Vassilvitskii, "k-means++: The Advantages of
%       Careful Seeding", Technical Report 2006-13, Stanford InfoLab, 2006.

function [initial_centers] = kmeans_plusplus(data, k)

centers = [];
initial_center = randperm(size(data,1) , 1); % pick random first center
centers = [centers; data(initial_center, :)]; % add first to list
data(initial_center, :) = []; % remove from set

for i=2:k
    
    current_dists = min(sp_dist2(data, centers), [], 2); % compute distance^2 to nearest existing center
    weights = current_dists ./ sum(current_dists);
    new_center_index = datasample(1:size(data,1), 1, 2, 'Weights', weights');
    centers = [centers; data(new_center_index, :)]; % add center to list
    data(new_center_index, :) = []; % remove from set
    
end

initial_centers = centers;