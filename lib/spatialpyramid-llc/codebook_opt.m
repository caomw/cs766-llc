%% Codebook Optimization Algorithm 4.1 from Section 4 of LLC paper
% http://www.ifp.illinois.edu/~jyang29/LLC.htm
%
% Ke Ma & Chris Bodden
%
% Inputs:
%   Binit - M x D initial codebook from k-means
%   X - N x D matrix of SIFT features for training images
%   lambda - regularization parameter for LLC optimization function
%   sigma - distance coefficient parameter
% Outputs:
%   B - M x D optimized codebook

function [B] = codebook_opt(Binit, X, lambda, sigma)
    [M,D] = size(Binit); % M = codebook size, D = feature size
    [N,~] = size(X); % N = num examples
    
    B = Binit;
    one_vec = ones(M, 1);
    fprintf('Optimizing codebook\n');
    for i = 1 : N
        fprintf('Descriptor %d out of %d', i, N);
        x = X(i,:);
        
        %locality constraint parameter
        d = sp_dist2(x, B);
        d = exp(d / sigma);
        d = mat2gray(d);
        d(d == 0) = 10^-16; %according to paper, 0 is not in range
        
        % coding
        B_1x = B - one_vec * x;
        C = B_1x * B_1x';
        c = (C + lambda * diag(d)) \ one_vec;
        c = c / sum(c);
        
        % remove bias
        id = abs(c) > 0.01;
        b = B(id,:);
        K = size(b, 1);
        fprintf(' ... K = %d\n', K);
        one_vec_tilde = ones(K, 1);
        b_1x = b - one_vec_tilde * x;
        C_tilde = b_1x * b_1x';
        c_tilde = C_tilde \ one_vec_tilde;
        c_tilde = c_tilde / sum(c_tilde);
        
        % update basis
        delta_b = -2 * c_tilde * (x - c_tilde' * b);
        mu = sqrt(1 / i);
        b = b - mu * delta_b / norm(c_tilde);
        b_norm = sqrt(sum(b .^ 2, 2));
        b_norm(b_norm < 1, :) = 1;
        b = b ./ (b_norm * ones(1, D));
        B(id, :) = b;
    end
end